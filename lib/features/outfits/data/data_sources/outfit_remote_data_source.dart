import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/models/outfit_record_model.dart';

/// The outfits made for each account (`users/{uid}/outfits/{signature}`)
/// and their pictures in Storage.
///
/// Every method throws [NetworkException] or [ServerException].
abstract interface class OutfitRemoteDataSource {
  /// Signatures of every outfit recorded for [accountId].
  Future<Set<String>> signatures(String accountId);

  /// The readable records of [accountId] for the date [forDate].
  Future<List<OutfitRecord>> recordsFor(String accountId, String forDate);

  /// Writes [record] with the time it was made.
  Future<void> write(String accountId, OutfitRecord record);

  /// Uploads [picture] to the Storage [path].
  Future<void> upload(
    String path,
    List<int> picture, {
    required String contentType,
  });

  /// The picture at the Storage [path].
  Future<List<int>> download(String path);
}

class OutfitRemoteDataSourceImpl implements OutfitRemoteDataSource {
  OutfitRemoteDataSourceImpl({
    required this._firestore,
    required this._storage,
  });

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// The largest picture downloaded.
  static const maxPictureBytes = 10 * 1024 * 1024;

  /// Error codes that mean the server could not be reached.
  static const _offline = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
    'retry-limit-exceeded',
  };

  CollectionReference<Map<String, dynamic>> _outfits(String accountId) =>
      _firestore.collection('users').doc(accountId).collection('outfits');

  @override
  Future<Set<String>> signatures(String accountId) => _guard(() async {
    final records = await _outfits(accountId).get();
    return {for (final record in records.docs) record.id};
  });

  @override
  Future<List<OutfitRecord>> recordsFor(String accountId, String forDate) =>
      _guard(() async {
        final records = await _outfits(
          accountId,
        ).where('forDate', isEqualTo: forDate).get();
        return [
          for (final record in records.docs)
            ?OutfitRecordModel.fromJson(
              record.id,
              record.data(),
              createdAt: switch (record.data()['createdAt']) {
                final Timestamp time => time.toDate(),
                _ => null,
              },
            ),
        ];
      });

  @override
  Future<void> write(String accountId, OutfitRecord record) => _guard(
    () => _outfits(accountId).doc(record.signature).set({
      ...OutfitRecordModel.toJson(record),
      'createdAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<void> upload(
    String path,
    List<int> picture, {
    required String contentType,
  }) => _guard(
    () => _storage
        .ref(path)
        .putData(
          Uint8List.fromList(picture),
          SettableMetadata(contentType: contentType),
        ),
  );

  @override
  Future<List<int>> download(String path) => _guard(() async {
    final picture = await _storage.ref(path).getData(maxPictureBytes);
    if (picture == null) {
      throw ServerException(
        StateError('No picture at the path'),
        StackTrace.current,
      );
    }
    return picture;
  });

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      if (_offline.contains(error.code)) throw NetworkException(error, stack);
      throw ServerException(error, stack);
    }
  }
}
