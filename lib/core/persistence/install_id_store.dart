import 'dart:math';

import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';

/// This install's id in the key-value store: random, made on first use.
abstract final class InstallIdStore {
  static const key = 'install_id';

  /// The kept id, or a new one, kept.
  static Future<InstallId> read(KeyValueStore store, {Random? random}) async {
    final kept = store.readString(key);
    if (kept != null && kept.isNotEmpty) return InstallId(kept);
    final source = random ?? Random.secure();
    final value = [
      for (var i = 0; i < 16; i++)
        source.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    await store.writeString(key, value);
    return InstallId(value);
  }
}
