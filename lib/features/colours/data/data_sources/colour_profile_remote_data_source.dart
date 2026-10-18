import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

/// The colours read from each face photo
/// (`users/{uid}/colorProfiles/{photo id}`). Every method throws
/// [NetworkException] or [ServerException].
abstract interface class ColourProfileRemoteDataSource {
  /// The colours read from the photo [photoId]; null when there are none.
  Future<Map<String, Object?>?> colours(String accountId, String photoId);

  /// The colours saved last, from any photo; null when there are none.
  Future<Map<String, Object?>?> latest(String accountId);

  Future<void> save(
    String accountId,
    String photoId,
    Map<String, Object?> colours,
  );
}

class ColourProfileRemoteDataSourceImpl
    implements ColourProfileRemoteDataSource {
  ColourProfileRemoteDataSourceImpl(this._firestore);
  final FirebaseFirestore _firestore;

  static const _offline = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
  };

  CollectionReference<Map<String, dynamic>> _profiles(String accountId) =>
      _firestore.collection('users').doc(accountId).collection('colorProfiles');

  @override
  Future<Map<String, Object?>?> colours(String accountId, String photoId) =>
      _guard(
        () async => (await _profiles(accountId).doc(photoId).get()).data(),
      );

  @override
  Future<Map<String, Object?>?> latest(String accountId) => _guard(() async {
    final saved = await _profiles(
      accountId,
    ).orderBy('analysedAt', descending: true).limit(1).get();
    return saved.docs.isEmpty ? null : saved.docs.first.data();
  });

  @override
  Future<void> save(
    String accountId,
    String photoId,
    Map<String, Object?> colours,
  ) => _guard(
    () => _profiles(accountId).doc(photoId).set({
      ...colours,
      'analysedAt': FieldValue.serverTimestamp(),
    }),
  );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      if (_offline.contains(error.code)) throw NetworkException(error, stack);
      throw ServerException(error, stack);
    }
  }
}
