import 'package:hive/hive.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';

class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore._(this._box);
  final Box<String> _box;

  static Future<HiveKeyValueStore> open({
    required String directory,
    required String boxName,
  }) async {
    try {
      return HiveKeyValueStore._(
        await Hive.openBox<String>(boxName, path: directory),
      );
    } on HiveError catch (error, stack) {
      throw CacheException(error, stack);
    } on Exception catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  String? readString(String key) {
    try {
      return _box.get(key);
    } on HiveError catch (error, stack) {
      throw CacheException(error, stack);
    } on Exception catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> writeString(String key, String value) async {
    try {
      await _box.put(key, value);
    } on HiveError catch (error, stack) {
      throw CacheException(error, stack);
    } on Exception catch (error, stack) {
      throw CacheException(error, stack);
    }
  }

  @override
  Future<void> close() => _box.close();
}
