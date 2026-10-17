import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/models/day_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/services/day_rules.dart';

/// What the chooser saw of an outfit's suggestions: whether it had been
/// suggested, and when last.
typedef SuggestionSeen = ({bool known, DateTime? lastAt});

/// Each account's days (`users/{uid}/days/{date}_{occasion}`) and the
/// outfits suggested to it (`users/{uid}/suggestions/{signature}`).
///
/// Every method throws [NetworkException] or [ServerException].
abstract interface class DayRemoteDataSource {
  /// The day [key] as it changes, starting from the phone's copy when
  /// there is one; null while there is none.
  Stream<Day?> watch(String accountId, String key);

  Future<Day?> day(String accountId, String key);

  /// When each of [signatures] was last suggested, null while that time is
  /// being written; signatures never suggested are left out.
  Future<Map<String, DateTime?>> suggested(
    String accountId,
    List<String> signatures,
  );

  /// Records on the outfit [signature]'s suggestion that the try-on
  /// refused the photo of [piece].
  Future<void> refuse(String accountId, String signature, String piece);

  /// The pieces whose photo the try-on refused for the account.
  Future<Set<String>> refusedPieces(String accountId);

  /// Claims the day [key] for [device] at [now] in one transaction, as
  /// [DayRules.claim] says. A [proposal] that makes a new day records its
  /// outfit as suggested too, unless the outfit was suggested since the
  /// chooser [seen] it: then nothing is written.
  Future<DayClaim> claim(
    String accountId,
    String key, {
    required Day? proposal,
    required SuggestionSeen seen,
    required String device,
    required DateTime now,
  });

  /// Writes [change] of the day [key] when [device] is making it; whether
  /// it did.
  Future<bool> change(
    String accountId,
    String key, {
    required String device,
    required Day Function(Day current) change,
  });
}

class DayRemoteDataSourceImpl implements DayRemoteDataSource {
  DayRemoteDataSourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  /// Firestore takes at most this many values in one `whereIn`.
  static const queryLimit = 30;

  /// Error codes that mean the server could not be reached.
  static const _offline = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
  };

  DocumentReference<Map<String, dynamic>> _account(String accountId) =>
      _firestore.collection('users').doc(accountId);

  DocumentReference<Map<String, dynamic>> _day(String accountId, String key) =>
      _account(accountId).collection('days').doc(key);

  CollectionReference<Map<String, dynamic>> _suggestions(String accountId) =>
      _account(accountId).collection('suggestions');

  static Day? _read(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data();
    if (data == null) return null;
    return DayModel.fromJson(data, updatedAt: _time(data['updatedAt']));
  }

  /// A server time in UTC; null while it is being written.
  static DateTime? _time(Object? value) => switch (value) {
    final Timestamp time => time.toDate().toUtc(),
    _ => null,
  };

  static Map<String, Object?> _write(Day day) => {
    ...DayModel.toJson(day),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  @override
  Stream<Day?> watch(String accountId, String key) =>
      _day(accountId, key).snapshots().map(_read).transform(_errors());

  @override
  Future<Day?> day(String accountId, String key) =>
      _guard(() async => _read(await _day(accountId, key).get()));

  @override
  Future<Map<String, DateTime?>> suggested(
    String accountId,
    List<String> signatures,
  ) => _guard(() async {
    final found = <String, DateTime?>{};
    for (var start = 0; start < signatures.length; start += queryLimit) {
      final chunk = signatures.skip(start).take(queryLimit).toList();
      final records = await _suggestions(
        accountId,
      ).where(FieldPath.documentId, whereIn: chunk).get();
      for (final record in records.docs) {
        found[record.id] = _time(record.data()['lastAt']);
      }
    }
    return found;
  });

  @override
  Future<void> refuse(String accountId, String signature, String piece) =>
      _guard(
        () => _suggestions(
          accountId,
        ).doc(signature).set({'refusedPiece': piece}, SetOptions(merge: true)),
      );

  @override
  Future<Set<String>> refusedPieces(String accountId) => _guard(() async {
    final records = await _suggestions(
      accountId,
    ).where('refusedPiece', isNull: false).get();
    return {
      for (final record in records.docs)
        if (record.data()['refusedPiece'] case final String piece) piece,
    };
  });

  @override
  Future<DayClaim> claim(
    String accountId,
    String key, {
    required Day? proposal,
    required SuggestionSeen seen,
    required String device,
    required DateTime now,
  }) => _guard(
    () => _firestore.runTransaction((transaction) async {
      final dayRef = _day(accountId, key);
      final current = _read(await transaction.get(dayRef));
      DocumentSnapshot<Map<String, dynamic>>? suggestion;
      if (current == null && proposal != null) {
        suggestion = await transaction.get(
          _suggestions(accountId).doc(proposal.signature),
        );
        final lastAt = _time(suggestion.data()?['lastAt']);
        final unchanged = seen.known
            ? suggestion.exists && lastAt == seen.lastAt
            : !suggestion.exists;
        if (!unchanged) return const DayConflict();
      }
      final decided = DayRules.claim(
        current: current,
        proposal: proposal,
        device: device,
        now: now,
      );
      final write = decided.write;
      if (write != null) {
        transaction.set(dayRef, _write(write));
        if (suggestion != null) {
          // Counted from the copy this transaction read.
          final before = suggestion.data();
          transaction.set(suggestion.reference, {
            'outfitId': write.outfitId,
            'lastForDate': TryOnJob.dateKey(write.date),
            'lastAt': FieldValue.serverTimestamp(),
            'times': ((before?['times'] as num?)?.toInt() ?? 0) + 1,
            'firstAt': before?['firstAt'] ?? FieldValue.serverTimestamp(),
          });
        }
      }
      return decided.claim;
    }),
  );

  @override
  Future<bool> change(
    String accountId,
    String key, {
    required String device,
    required Day Function(Day current) change,
  }) => _guard(
    () => _firestore.runTransaction((transaction) async {
      final dayRef = _day(accountId, key);
      final current = _read(await transaction.get(dayRef));
      if (current == null ||
          current.status != DayStatus.making ||
          current.device != device) {
        return false;
      }
      transaction.set(dayRef, _write(change(current)));
      return true;
    }),
  );

  static Exception _translate(FirebaseException error, StackTrace stack) =>
      _offline.contains(error.code)
      ? NetworkException(error, stack)
      : ServerException(error, stack);

  static StreamTransformer<Day?, Day?> _errors() =>
      StreamTransformer.fromHandlers(
        handleError: (error, stack, sink) => sink.addError(
          error is FirebaseException ? _translate(error, stack) : error,
          stack,
        ),
      );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      throw _translate(error, stack);
    }
  }
}
