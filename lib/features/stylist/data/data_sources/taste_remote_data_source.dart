import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

/// Each account's taste signals, in `users/{uid}/stylist/state`. Every
/// method throws [NetworkException] or [ServerException].
abstract interface class TasteRemoteDataSource {
  /// The signals on [accountId]'s account.
  Future<List<Object?>> signals(String accountId);

  /// Adds [signals] beside the account's; one already there stays once.
  Future<void> add(String accountId, List<Map<String, Object?>> signals);
}

class TasteRemoteDataSourceImpl implements TasteRemoteDataSource {
  TasteRemoteDataSourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  /// What the record's signals are, for reading it in years to come.
  static const version = 1;

  static const _offline = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
  };

  DocumentReference<Map<String, dynamic>> _state(String accountId) => _firestore
      .collection('users')
      .doc(accountId)
      .collection('stylist')
      .doc('state');

  @override
  Future<List<Object?>> signals(String accountId) => _guard(() async {
    final state = await _state(accountId).get();
    return switch (state.data()?['signals']) {
      final List<Object?> signals => signals,
      _ => const [],
    };
  });

  @override
  Future<void> add(String accountId, List<Map<String, Object?>> signals) =>
      _guard(
        () => _state(accountId).set({
          'version': version,
          'signals': FieldValue.arrayUnion(signals),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true)),
      );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      throw _offline.contains(error.code)
          ? NetworkException(error, stack)
          : ServerException(error, stack);
    }
  }
}
