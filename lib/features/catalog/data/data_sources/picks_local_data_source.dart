import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';

abstract interface class PicksLocalDataSource {
  /// Empty when nothing readable is saved. Throws CacheException.
  Set<String> picks();

  /// Throws CacheException.
  Future<void> save(Set<String> picks);
}

class PicksLocalDataSourceImpl implements PicksLocalDataSource {
  PicksLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const picksKey = 'picks';

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
}
