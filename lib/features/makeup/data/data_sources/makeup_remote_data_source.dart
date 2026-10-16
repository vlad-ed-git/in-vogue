import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

/// The makeup looks of each account (`users/{uid}/makeupLooks/{outfit
/// signature}`), their pictures in Storage, and the colours analysed from
/// each face photo (`users/{uid}/colorProfiles/{photo id}`).
///
/// Every method throws [NetworkException] or [ServerException].
abstract interface class MakeupRemoteDataSource {
  /// The colours analysed from the photo [photoId]; null when there are
  /// none.
  Future<Map<String, Object?>?> colours(String accountId, String photoId);

  Future<void> saveColours(
    String accountId,
    String photoId,
    Map<String, Object?> colours,
  );

  /// The record of the look for [signature]; null when there is none.
  Future<Map<String, Object?>?> look(String accountId, String signature);

  /// The signature and record of the look made last; null when there is
  /// none.
  Future<(String, Map<String, Object?>)?> latestLook(String accountId);

  /// Writes the record of the look for [signature] with the time it was
  /// made.
  Future<void> writeLook(
    String accountId,
    String signature,
    Map<String, Object?> record,
  );

  /// Uploads [picture] to the Storage [path].
  Future<void> upload(
    String path,
    List<int> picture, {
    required String contentType,
  });

  /// The picture at the Storage [path].
  Future<List<int>> download(String path);
}

class MakeupRemoteDataSourceImpl implements MakeupRemoteDataSource {
  MakeupRemoteDataSourceImpl({
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

  DocumentReference<Map<String, dynamic>> _account(String accountId) =>
      _firestore.collection('users').doc(accountId);

  CollectionReference<Map<String, dynamic>> _looks(String accountId) =>
      _account(accountId).collection('makeupLooks');

  @override
  Future<Map<String, Object?>?> colours(String accountId, String photoId) =>
      _guard(
        () async => (await _account(
          accountId,
        ).collection('colorProfiles').doc(photoId).get()).data(),
      );

  @override
  Future<void> saveColours(
    String accountId,
    String photoId,
    Map<String, Object?> colours,
  ) => _guard(
    () => _account(accountId).collection('colorProfiles').doc(photoId).set({
      ...colours,
      'analysedAt': FieldValue.serverTimestamp(),
    }),
  );

  @override
  Future<Map<String, Object?>?> look(String accountId, String signature) =>
      _guard(() async => (await _looks(accountId).doc(signature).get()).data());

  @override
  Future<(String, Map<String, Object?>)?> latestLook(String accountId) =>
      _guard(() async {
        final latest = await _looks(
          accountId,
        ).orderBy('createdAt', descending: true).limit(1).get();
        if (latest.docs.isEmpty) return null;
        final record = latest.docs.single;
        return (record.id, record.data());
      });

  @override
  Future<void> writeLook(
    String accountId,
    String signature,
    Map<String, Object?> record,
  ) => _guard(
    () => _looks(accountId).doc(signature).set({
      ...record,
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
