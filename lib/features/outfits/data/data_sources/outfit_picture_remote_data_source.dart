import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

/// Outfit pictures in Storage.
///
/// Every method throws [NetworkException] or [ServerException].
abstract interface class OutfitPictureRemoteDataSource {
  /// Uploads [picture] to the Storage [path].
  Future<void> upload(
    String path,
    List<int> picture, {
    required String contentType,
  });

  /// The picture at the Storage [path].
  Future<List<int>> download(String path);
}

class OutfitPictureRemoteDataSourceImpl
    implements OutfitPictureRemoteDataSource {
  OutfitPictureRemoteDataSourceImpl(this._storage);
  final FirebaseStorage _storage;

  /// The largest picture downloaded.
  static const maxPictureBytes = 10 * 1024 * 1024;

  /// Error codes that mean the server could not be reached.
  static const _offline = {'retry-limit-exceeded', 'network-request-failed'};

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
