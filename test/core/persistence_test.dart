import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/hive_key_value_store.dart';
import 'package:in_vogue/core/persistence/sqlite_cache.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory directory;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('in_vogue_storage_');
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });

  test(
    'Hive survives reopen and isolates development from production',
    () async {
      var development = await HiveKeyValueStore.open(
        directory: directory.path,
        boxName: 'development',
      );
      final production = await HiveKeyValueStore.open(
        directory: directory.path,
        boxName: 'production',
      );
      addTearDown(production.close);
      expect(development.readString('language'), isNull);
      await development.writeString('language', 'es');
      expect(production.readString('language'), isNull);
      await development.close();
      development = await HiveKeyValueStore.open(
        directory: directory.path,
        boxName: 'development',
      );
      addTearDown(development.close);
      expect(development.readString('language'), 'es');
    },
  );

  test('closed Hive storage raises a recoverable cache exception', () async {
    final store = await HiveKeyValueStore.open(
      directory: directory.path,
      boxName: 'closed',
    );
    await store.close();
    expect(() => store.readString('language'), throwsA(isA<CacheException>()));
    await expectLater(
      store.writeString('language', 'es'),
      throwsA(isA<CacheException>()),
    );
  });

  group('SQLite cache', () {
    late SqliteCache cache;
    final expiry = DateTime.utc(2026, 10, 16);
    setUp(() async {
      sqfliteFfiInit();
      cache = await SqliteCache.open(
        factory: databaseFactoryFfi,
        path: path.join(directory.path, 'cache.sqlite'),
      );
    });
    tearDown(() async {
      await cache.close();
    });

    test(
      'keeps valid data across reopen and expires at the exact boundary',
      () async {
        await cache.write('forecast', '{"city":"Shanghai"}', expiresAt: expiry);
        await cache.close();
        cache = await SqliteCache.open(
          factory: databaseFactoryFfi,
          path: path.join(directory.path, 'cache.sqlite'),
        );
        expect(
          await cache.read(
            'forecast',
            now: expiry.subtract(const Duration(milliseconds: 1)),
          ),
          '{"city":"Shanghai"}',
        );
        expect(await cache.read('forecast', now: expiry), isNull);
      },
    );

    test(
      'replaces by key, safely stores quotes, and clears cached data',
      () async {
        const key = "forecast'; DROP TABLE cached_documents; --";
        await cache.write(key, 'old', expiresAt: expiry);
        await cache.write(key, 'new', expiresAt: expiry);
        expect(
          await cache.read(key, now: expiry.subtract(const Duration(days: 1))),
          'new',
        );
        await cache.clear();
        expect(await cache.read(key, now: expiry), isNull);
      },
    );
  });
}
