import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/wardrobe/data/models/wardrobe_outfit_model.dart';

/// The outfits of each account (`users/{uid}/wardrobe/{id}`) and their
/// photos in Storage (`users/{uid}/wardrobe/{id}.<ext>`). Every method
/// throws [NetworkException] or [ServerException]; the stream reports them
/// as errors.
abstract interface class WardrobeRemoteDataSource {
  /// The account's outfit records, newest first, by id.
  Stream<List<(String, Map<String, Object?>)>> watch(String accountId);

  /// An id for a new outfit.
  String newId(String accountId);

  /// Uploads [file] as [id]'s photo; its Storage path and download URL.
  Future<(String, String)> uploadPhoto(
    String accountId,
    String id, {
    required String file,
    required String contentType,
  });

  Future<void> save(String accountId, String id, Map<String, Object?> json);

  /// Deletes [id]'s record and its photo.
  Future<void> delete(String accountId, String id);
}

class WardrobeRemoteDataSourceImpl implements WardrobeRemoteDataSource {
  WardrobeRemoteDataSourceImpl({
    required this._firestore,
    required this._storage,
  });

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  static const _offline = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
  };

  CollectionReference<Map<String, dynamic>> _outfits(String accountId) =>
      _firestore.collection('users').doc(accountId).collection('wardrobe');

  @override
  Stream<List<(String, Map<String, Object?>)>> watch(String accountId) =>
      _outfits(accountId)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .map((saved) => [for (final doc in saved.docs) (doc.id, doc.data())])
          .transform(
            StreamTransformer.fromHandlers(
              handleError: (error, stack, sink) => sink.addError(
                error is FirebaseException ? _translate(error, stack) : error,
                stack,
              ),
            ),
          );

  @override
  String newId(String accountId) => _outfits(accountId).doc().id;

  @override
  Future<(String, String)> uploadPhoto(
    String accountId,
    String id, {
    required String file,
    required String contentType,
  }) => _guard(() async {
    final extension = contentType == 'image/png' ? 'png' : 'jpg';
    final path = 'users/$accountId/wardrobe/$id.$extension';
    final uploaded = await _storage
        .ref(path)
        .putFile(File(file), SettableMetadata(contentType: contentType));
    return (path, await uploaded.ref.getDownloadURL());
  });

  @override
  Future<void> save(String accountId, String id, Map<String, Object?> json) =>
      _guard(() => _outfits(accountId).doc(id).set(json));

  @override
  Future<void> delete(String accountId, String id) => _guard(() async {
    final record = await _outfits(accountId).doc(id).get();
    final photo = WardrobeOutfitModel.photoPathOf(record.data() ?? const {});
    if (photo != null) {
      try {
        await _storage.ref(photo).delete();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found') rethrow;
      }
    }
    await _outfits(accountId).doc(id).delete();
  });

  static Exception _translate(FirebaseException error, StackTrace stack) =>
      _offline.contains(error.code)
      ? NetworkException(error, stack)
      : ServerException(error, stack);

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      throw _translate(error, stack);
    }
  }
}
