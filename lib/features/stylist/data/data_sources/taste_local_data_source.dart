import 'dart:convert';

import 'package:in_vogue/core/persistence/key_value_store.dart';

/// The taste signals on this phone. Throws CacheException.
abstract interface class TasteLocalDataSource {
  /// Empty when nothing readable is kept.
  List<Object?> signals();

  Future<void> save(List<Object?> signals);

  Future<void> forget();
}

class TasteLocalDataSourceImpl implements TasteLocalDataSource {
  TasteLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const key = 'taste_signals';

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
  Future<void> forget() => _store.delete(key);
}
