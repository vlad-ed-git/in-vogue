import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/persistence/install_id_store.dart';

import '../helpers/memory_store.dart';

void main() {
  test('makes an install id once and keeps it', () async {
    final store = MemoryStore();
    final first = await InstallIdStore.read(store, random: Random(1));
    expect(first.value, hasLength(32));
    expect(first.value, matches(RegExp(r'^[0-9a-f]{32}$')));
    expect(store.values[InstallIdStore.key], first.value);
    expect(await InstallIdStore.read(store, random: Random(2)), first);
  });
}
