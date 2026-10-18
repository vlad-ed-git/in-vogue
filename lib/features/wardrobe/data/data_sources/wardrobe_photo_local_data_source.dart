import 'dart:io';

import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:path/path.dart' as p;

/// The wardrobe's photos on this phone, at `<folder>/{uid}/{id}.<ext>`.
/// Every method throws [CacheException].
abstract interface class WardrobePhotoLocalDataSource {
  /// Copies [file] in as [id]'s photo for [accountId]; its path.
  Future<String> keep(String accountId, String id, String file);

  /// [id]'s photo on this phone; null when there is none.
  String? photo(String accountId, String id);

  Future<void> delete(String accountId, String id);

  /// Deletes every photo of [accountId].
  Future<void> forget(String accountId);
}

class WardrobePhotoLocalDataSourceImpl implements WardrobePhotoLocalDataSource {
  const WardrobePhotoLocalDataSourceImpl(this._folder);

  final String _folder;

  Directory _account(String accountId) => Directory(p.join(_folder, accountId));

  File? _existing(String accountId, String id) {
    final folder = _account(accountId);
    if (!folder.existsSync()) return null;
    for (final extension in const ['jpg', 'png']) {
      final file = File(p.join(folder.path, '$id.$extension'));
      if (file.existsSync()) return file;
    }
    return null;
  }

  @override
  Future<String> keep(String accountId, String id, String file) async {
    try {
      final extension = p.extension(file).toLowerCase() == '.png'
          ? 'png'
          : 'jpg';
      final folder = await _account(accountId).create(recursive: true);
      final kept = await File(file).copy(p.join(folder.path, '$id.$extension'));
      return kept.path;
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  String? photo(String accountId, String id) => _existing(accountId, id)?.path;

  @override
  Future<void> delete(String accountId, String id) async {
    try {
      await _existing(accountId, id)?.delete();
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> forget(String accountId) async {
    try {
      final folder = _account(accountId);
      if (folder.existsSync()) await folder.delete(recursive: true);
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
