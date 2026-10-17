import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';

abstract interface class PicksLocalDataSource {
  /// Empty when nothing readable is saved. Throws CacheException.
  Set<String> picks();

  /// Throws CacheException.
  Future<void> save(Set<String> picks);

  /// The picks last saved on [accountId]'s account; empty for any other
  /// account, or when nothing readable is saved. Throws CacheException.
  Set<String> synced(String accountId);

  /// Throws CacheException.
  Future<void> saveSynced(String accountId, Set<String> picks);

  /// Throws CacheException.
  Future<void> forgetSynced();
}

class PicksLocalDataSourceImpl implements PicksLocalDataSource {
  PicksLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const picksKey = 'picks';
  static const syncedKey = 'picks_synced';

  @override
  Set<String> picks() {
    final saved = _store.readString(picksKey);
    if (saved == null) return {};
    try {
      return switch (jsonDecode(saved)) {
        final List<Object?> ids => ids.whereType<String>().toSet(),
        _ => {},
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> save(Set<String> picks) =>
      _store.writeString(picksKey, jsonEncode(picks.toList()));

  @override
  Set<String> synced(String accountId) {
    final saved = _store.readString(syncedKey);
    if (saved == null) return {};
    try {
      return switch (jsonDecode(saved)) {
        {'account': final String account, 'picks': final List<Object?> ids}
            when account == accountId =>
          ids.whereType<String>().toSet(),
        _ => {},
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> saveSynced(String accountId, Set<String> picks) =>
      _store.writeString(
        syncedKey,
        jsonEncode({'account': accountId, 'picks': picks.toList()}),
      );

  @override
  Future<void> forgetSynced() => _store.delete(syncedKey);
}
