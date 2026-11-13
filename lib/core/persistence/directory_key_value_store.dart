import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:path/path.dart' as path;

/// Background state in separate files; never opens the foreground Hive box.
class DirectoryKeyValueStore implements KeyValueStore {
  const DirectoryKeyValueStore(this.directory);
  final String directory;

  File _file(String key) =>
      File(path.join(directory, sha256.convert(utf8.encode(key)).toString()));

  @override
  String? readString(String key) {
    try {
      final file = _file(key);
      return file.existsSync() ? file.readAsStringSync() : null;
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      final file = _file(key);
      await file.parent.create(recursive: true);
      final temporary = await file.parent.createTemp('.writing-');
      try {
        final next = File(path.join(temporary.path, 'value'));
        await next.writeAsString(value, flush: true);
        await next.rename(file.path);
      } finally {
        if (temporary.existsSync()) await temporary.delete(recursive: true);
      }
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> delete(String key) async {
    try {
      final file = _file(key);
      if (file.existsSync()) await file.delete();
    } on FileSystemException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> close() async {}
}
