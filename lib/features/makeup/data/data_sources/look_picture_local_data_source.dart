import 'dart:convert';
import 'dart:io';

import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:path/path.dart' as p;

/// Makeup pictures kept privately on the phone, in a folder per account
/// and look.
abstract interface class LookPictureLocalDataSource {
  /// The kept picture [name] of the look [look]; null when there is none.
  /// Throws [CacheException].
  String? kept(String accountId, String look, String name);

  /// Keeps [picture] as [name] of the look [look]; its file. Throws
  /// [CacheException].
  Future<String> keep(
    String accountId,
    String look,
    String name,
    List<int> picture,
  );

  /// The record kept with the look [look]'s pictures; null when there is
  /// none. Throws [CacheException].
  Map<String, Object?>? record(String accountId, String look);

  /// Keeps [record] with the look [look]'s pictures. Throws
  /// [CacheException].
  Future<void> keepRecord(
    String accountId,
    String look,
    Map<String, Object?> record,
  );

  /// Deletes every picture and record of [accountId]. Throws
  /// [CacheException].
  Future<void> forget(String accountId);
}

class LookPictureLocalDataSourceImpl implements LookPictureLocalDataSource {
  LookPictureLocalDataSourceImpl(this._directory);

  /// The folder that holds each account's folder.
  final String _directory;

  String _file(String accountId, String look, String name) =>
      p.join(_directory, accountId, look, name);

  @override
  String? kept(String accountId, String look, String name) {
    final file = _file(accountId, look, name);
    try {
      return File(file).existsSync() ? file : null;
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<String> keep(
    String accountId,
    String look,
    String name,
    List<int> picture,
  ) async {
    final file = File(_file(accountId, look, name));
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

  /// The record's file: not a picture's name, as those have an image type.
  static const _record = 'look.json';

  @override
  Map<String, Object?>? record(String accountId, String look) {
    final file = File(_file(accountId, look, _record));
    try {
      if (!file.existsSync()) return null;
      return switch (jsonDecode(file.readAsStringSync())) {
        final Map<String, Object?> record => record,
        _ => null,
      };
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> keepRecord(
    String accountId,
    String look,
    Map<String, Object?> record,
  ) => keep(accountId, look, _record, utf8.encode(jsonEncode(record)));

  @override
  Future<void> forget(String accountId) async {
    final folder = Directory(p.join(_directory, accountId));
    try {
      if (folder.existsSync()) await folder.delete(recursive: true);
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
