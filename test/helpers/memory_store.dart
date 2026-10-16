import 'package:in_vogue/core/persistence/key_value_store.dart';

/// A [KeyValueStore] held in memory.
class MemoryStore implements KeyValueStore {
  final values = <String, String>{};

  @override
  String? readString(String key) => values[key];

  @override
  Future<void> writeString(String key, String value) async =>
      values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);

  @override
  Future<void> close() async {}
}
