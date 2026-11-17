import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';

/// The taste signals on this phone. Throws CacheException.
abstract interface class TasteLocalDataSource {
  /// Empty when nothing readable is kept.
  List<Object?> signals();

  Future<void> save(List<Object?> signals);

  /// Ids of the signals the account has; empty when none are known.
  Set<String> synced();

  Future<void> saveSynced(Set<String> ids);

  /// Forgets the signals and which the account has.
  Future<void> forget();
}

class TasteLocalDataSourceImpl implements TasteLocalDataSource {
  TasteLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const key = 'taste_signals';
  static const syncedKey = 'taste_synced';

  @override
  List<Object?> signals() {
    final saved = _store.readString(key);
    if (saved == null) return const [];
    try {
      return switch (jsonDecode(saved)) {
        final List<Object?> signals => signals,
        _ => const [],
      };
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> save(List<Object?> signals) =>
      _store.writeString(key, jsonEncode(signals));

  @override
  Set<String> synced() {
    final saved = _store.readString(syncedKey);
    if (saved == null) return const {};
    try {
      return switch (jsonDecode(saved)) {
        final List<Object?> ids => {...ids.whereType<String>()},
        _ => const {},
      };
    } on FormatException {
      return const {};
    }
  }

  @override
  Future<void> saveSynced(Set<String> ids) =>
      _store.writeString(syncedKey, jsonEncode([...ids]));

  @override
  Future<void> forget() async {
    await _store.delete(key);
    await _store.delete(syncedKey);
  }
}
