import 'dart:convert';
import 'dart:io';

import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:path/path.dart' as p;

abstract interface class PhotoStoreDataSource {
  /// Copies the photo at [source] into the private folder as the [role]
  /// photo and deletes the one it replaces. Throws [CacheException].
  Future<UserPhoto> keep(String source, PhotoRole role);

  /// Null before the first photo or when its file is gone. Throws
  /// [CacheException].
  UserPhoto? kept(PhotoRole role);

  /// Deletes the [role] photo and its record. Throws [CacheException].
  Future<void> forget(PhotoRole role);
}

/// Photos in a private folder, with their file names and revisions in the
/// key-value store. Names, not full paths, are stored because the app's
/// folder can move when iOS updates the app.
class PhotoStoreDataSourceImpl implements PhotoStoreDataSource {
  PhotoStoreDataSourceImpl({required this._directory, required this._store});

  final String _directory;
  final KeyValueStore _store;

  static String _key(PhotoRole role) => 'photo_${role.name}';

  @override
  Future<UserPhoto> keep(String source, PhotoRole role) async {
    final previous = _record(role);
    final revision = (previous?.revision ?? 0) + 1;
    final extension = p.extension(source).toLowerCase();
    final name =
        '${role.name}-$revision${extension.isEmpty ? '.jpg' : extension}';
    try {
      await Directory(_directory).create(recursive: true);
      await File(source).copy(p.join(_directory, name));
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
    await _store.writeString(
      _key(role),
      jsonEncode({'name': name, 'revision': revision}),
    );
    if (previous != null && previous.name != name) {
      try {
        await File(p.join(_directory, previous.name)).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
    return UserPhoto(
      role: role,
      path: p.join(_directory, name),
      revision: revision,
    );
  }

  @override
  UserPhoto? kept(PhotoRole role) {
    final record = _record(role);
    if (record == null) return null;
    final file = p.join(_directory, record.name);
    if (!File(file).existsSync()) return null;
    return UserPhoto(role: role, path: file, revision: record.revision);
  }

  @override
  Future<void> forget(PhotoRole role) async {
    final record = _record(role);
    if (record != null) {
      try {
        await File(p.join(_directory, record.name)).delete();
      } on FileSystemException {
        // Already gone.
      }
    }
    await _store.delete(_key(role));
  }

  ({String name, int revision})? _record(PhotoRole role) {
    final saved = _store.readString(_key(role));
    if (saved == null) return null;
    try {
      return switch (jsonDecode(saved)) {
        {'name': final String name, 'revision': final int revision} => (
          name: name,
          revision: revision,
        ),
        _ => null,
      };
    } on FormatException {
      return null;
    }
  }
}
