import 'package:in_vogue/core/persistence/key_value_store.dart';

abstract interface class ProfileLocalDataSource {
  /// Throws CacheException.
  String? name();

  /// Throws CacheException.
  Future<void> saveName(String name);
}

class ProfileLocalDataSourceImpl implements ProfileLocalDataSource {
  ProfileLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const nameKey = 'profile_name';

  @override
  String? name() => _store.readString(nameKey);

  @override
  Future<void> saveName(String name) => _store.writeString(nameKey, name);
}
