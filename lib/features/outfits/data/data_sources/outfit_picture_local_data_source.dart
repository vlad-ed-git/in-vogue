import 'dart:io';

import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:path/path.dart' as p;

/// Outfit pictures kept privately on the phone, in a folder per account.
abstract interface class OutfitPictureLocalDataSource {
  /// The kept picture [name] of [accountId]; null when there is none.
  /// Throws [CacheException].
  String? kept(String accountId, String name);

  /// Keeps [picture] as [name] for [accountId]; its file. Throws
  /// [CacheException].
  Future<String> keep(String accountId, String name, List<int> picture);

  /// Deletes every picture of [accountId]. Throws [CacheException].
  Future<void> forget(String accountId);
}

class OutfitPictureLocalDataSourceImpl implements OutfitPictureLocalDataSource {
  OutfitPictureLocalDataSourceImpl(this._directory);

  /// The folder that holds each account's folder.
  final String _directory;

  String _file(String accountId, String name) =>
      p.join(_directory, accountId, name);

  @override
  String? kept(String accountId, String name) {
    final file = _file(accountId, name);
    try {
      return File(file).existsSync() ? file : null;
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> forget(String accountId) async {
    final folder = Directory(p.join(_directory, accountId));
    try {
      if (folder.existsSync()) await folder.delete(recursive: true);
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<String> keep(String accountId, String name, List<int> picture) async {
    final file = File(_file(accountId, name));
    try {
      await file.parent.create(recursive: true);
      // Written beside it first, so a cut-short write never shows.
      final partial = File('${file.path}.part');
      await partial.writeAsBytes(picture, flush: true);
      await partial.rename(file.path);
      return file.path;
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
