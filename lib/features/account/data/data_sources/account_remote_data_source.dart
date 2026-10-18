import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

/// The account in Firestore (`users/{uid}`) and its photos in Storage.
///
/// Every method throws [NetworkException] or [ServerException].
abstract interface class AccountRemoteDataSource {
  /// The account document's fields; null when it does not exist.
  Future<Map<String, Object?>?> readAccount(String accountId);

  /// Merges [fields] into the account document with the time of the update,
  /// and the time it was created when [created] is set.
  Future<void> writeAccount(
    String accountId,
    Map<String, Object?> fields, {
    required bool created,
  });

  /// Uploads the image [file] to the Storage [path]; its download URL.
  Future<String> uploadPhoto({
    required String path,
    required String file,
    required String contentType,
  });

  /// The download URL of the Storage object at [path].
  Future<String> photoUrl(String path);

  /// Deletes the Storage object at [path].
  Future<void> deletePhoto(String path);

  /// The bytes of the Storage object at [path].
  Future<List<int>> downloadPhoto(String path);

  /// Ids of the colourways on the account's wishlist.
  Future<Set<String>> wishlist(String accountId);

  /// Adds [add] to the wishlist and removes [remove] from it.
  Future<void> writeWishlist(
    String accountId, {
    required Set<String> add,
    required Set<String> remove,
  });

  /// Deletes the account document, everything under it, and every file of
  /// the account in Storage.
  Future<void> deleteAccount(String accountId);
}

class AccountRemoteDataSourceImpl implements AccountRemoteDataSource {
  AccountRemoteDataSourceImpl({
    required this._firestore,
    required this._storage,
  });

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Writes per batch, under Firestore's limit of 500.
  static const batchSize = 400;

  /// The largest photo downloaded.
  static const maxPhotoBytes = 10 * 1024 * 1024;

  /// Error codes that mean the server could not be reached.
  static const _offline = {
    'unavailable',
    'deadline-exceeded',
    'network-request-failed',
    'retry-limit-exceeded',
  };

  DocumentReference<Map<String, dynamic>> _account(String accountId) =>
      _firestore.collection('users').doc(accountId);

  CollectionReference<Map<String, dynamic>> _wishlist(String accountId) =>
      _account(accountId).collection('wishlist');

  @override
  Future<Map<String, Object?>?> readAccount(String accountId) =>
      _guard(() async {
        final snapshot = await _account(accountId).get();
        return snapshot.exists ? snapshot.data() : null;
      });

  @override
  Future<void> writeAccount(
    String accountId,
    Map<String, Object?> fields, {
    required bool created,
  }) => _guard(
    () => _account(accountId).set({
      ...fields,
      if (created) 'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)),
  );

  @override
  Future<String> uploadPhoto({
    required String path,
    required String file,
    required String contentType,
  }) => _guard(() async {
    final uploaded = await _storage
        .ref(path)
        .putFile(File(file), SettableMetadata(contentType: contentType));
    return uploaded.ref.getDownloadURL();
  });

  @override
  Future<String> photoUrl(String path) =>
      _guard(() => _storage.ref(path).getDownloadURL());

  @override
  Future<void> deletePhoto(String path) =>
      _guard(() => _storage.ref(path).delete());

  @override
  Future<List<int>> downloadPhoto(String path) => _guard(() async {
    final photo = await _storage.ref(path).getData(maxPhotoBytes);
    if (photo == null) {
      throw ServerException(
        StateError('No photo at the path'),
        StackTrace.current,
      );
    }
    return photo;
  });

  @override
  Future<Set<String>> wishlist(String accountId) => _guard(() async {
    final saved = await _wishlist(accountId).get();
    return {for (final document in saved.docs) document.id};
  });

  @override
  Future<void> writeWishlist(
    String accountId, {
    required Set<String> add,
    required Set<String> remove,
  }) => _guard(() async {
    final collection = _wishlist(accountId);
    final writes = <void Function(WriteBatch)>[
      for (final id in add)
        (batch) => batch.set(collection.doc(id), {
          'addedAt': FieldValue.serverTimestamp(),
        }),
      for (final id in remove) (batch) => batch.delete(collection.doc(id)),
    ];
    for (var start = 0; start < writes.length; start += batchSize) {
      final batch = _firestore.batch();
      for (final write in writes.skip(start).take(batchSize)) {
        write(batch);
      }
      await batch.commit();
    }
  });

  /// Collections under an account document.
  static const _collections = [
    'wishlist',
    'days',
    'suggestions',
    'colorProfiles',
    'tryOns',
  ];

  @override
  Future<void> deleteAccount(String accountId) => _guard(() async {
    for (final name in _collections) {
      final collection = _account(accountId).collection(name);
      // A page at a time, however many documents there are.
      while (true) {
        final page = await collection.limit(batchSize).get();
        if (page.docs.isEmpty) break;
        final batch = _firestore.batch();
        for (final document in page.docs) {
          batch.delete(document.reference);
        }
        await batch.commit();
      }
    }
    await _account(accountId).delete();
    await _deleteFolder(_storage.ref('users/$accountId'));
  });

  Future<void> _deleteFolder(Reference folder) async {
    final listed = await folder.listAll();
    for (final item in listed.items) {
      await item.delete();
    }
    for (final prefix in listed.prefixes) {
      await _deleteFolder(prefix);
    }
  }

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on FirebaseException catch (error, stack) {
      if (_offline.contains(error.code)) throw NetworkException(error, stack);
      throw ServerException(error, stack);
    }
  }
}
