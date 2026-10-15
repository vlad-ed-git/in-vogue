abstract interface class KeyValueStore {
  String? readString(String key);
  Future<void> writeString(String key, String value);
  Future<void> close();
}
