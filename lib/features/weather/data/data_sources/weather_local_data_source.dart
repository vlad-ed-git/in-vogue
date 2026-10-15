import 'dart:convert';

import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/sqlite_cache.dart';
import 'package:sqflite/sqflite.dart' show DatabaseException;

/// An Open-Meteo answer and when it was fetched.
typedef SavedForecast = ({Map<String, Object?> json, DateTime fetchedAt});

abstract interface class WeatherLocalDataSource {
  /// The forecast kept under [key]; null when none is readable. Throws
  /// [CacheException].
  Future<SavedForecast?> read({required String key, required DateTime now});

  /// Keeps [json] under [key]. Throws [CacheException].
  Future<void> save({
    required String key,
    required Map<String, Object?> json,
    required DateTime fetchedAt,
  });
}

class WeatherLocalDataSourceImpl implements WeatherLocalDataSource {
  WeatherLocalDataSourceImpl(this._cache);
  final SqliteCache _cache;

  /// How long a forecast is kept for use offline.
  static const keepFor = Duration(days: 2);

  static String _cacheKey(String key) => 'forecast:$key';

  @override
  Future<SavedForecast?> read({
    required String key,
    required DateTime now,
  }) async {
    final String? value;
    try {
      value = await _cache.read(_cacheKey(key), now: now);
    } on DatabaseException catch (error, stack) {
      throw CacheException(error, stack);
    }
    if (value == null) return null;
    try {
      if (jsonDecode(value) case {
        'fetchedAt': final String fetchedAt,
        'forecast': final Map<String, Object?> json,
      }) {
        return (json: json, fetchedAt: DateTime.parse(fetchedAt));
      }
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> save({
    required String key,
    required Map<String, Object?> json,
    required DateTime fetchedAt,
  }) async {
    try {
      await _cache.write(
        _cacheKey(key),
        jsonEncode({
          'fetchedAt': fetchedAt.toUtc().toIso8601String(),
          'forecast': json,
        }),
        expiresAt: fetchedAt.add(keepFor),
      );
    } on DatabaseException catch (error, stack) {
      throw CacheException(error, stack);
    }
  }
}
