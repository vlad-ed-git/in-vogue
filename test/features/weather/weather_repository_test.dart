import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/sqlite_cache.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_local_data_source.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:in_vogue/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/repositories/weather_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'open_meteo_test.dart' show openMeteoJson;
import 'weather_repository_test.mocks.dart';

const _place = UserLocation(latitude: 40.71, longitude: -74.01);
final _now = DateTime.utc(2026, 10, 15, 22);

@GenerateMocks([
  WeatherRemoteDataSource,
  WeatherLocalDataSource,
  WeatherRepository,
  LogMessages,
])
void main() {
  group('WeatherLocalDataSourceImpl', () {
    late SqliteCache cache;
    late WeatherLocalDataSourceImpl source;

    setUpAll(sqfliteFfiInit);
    setUp(() async {
      cache = await SqliteCache.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
      source = WeatherLocalDataSourceImpl(cache);
    });
    tearDown(() => cache.close());

    test('keeps a forecast with its fetch time for two days', () async {
      final json = openMeteoJson(hours: 2);
      await source.save(key: 'here', json: json, fetchedAt: _now);
      final saved = await source.read(key: 'here', now: _now);
      expect(saved?.json, json);
      expect(saved?.fetchedAt, _now);
      expect(await source.read(key: 'elsewhere', now: _now), isNull);
      expect(
        await source.read(
          key: 'here',
          now: _now.add(const Duration(days: 2, minutes: 1)),
        ),
        isNull,
      );
    });

    test('reports a closed database as a cache problem', () async {
      await cache.close();
      await expectLater(
        source.read(key: 'here', now: _now),
        throwsA(isA<CacheException>()),
      );
      await expectLater(
        source.save(key: 'here', json: const {}, fetchedAt: _now),
        throwsA(isA<CacheException>()),
      );
    });
  });

  group('WeatherRepositoryImpl', () {
    late MockWeatherRemoteDataSource remote;
    late MockWeatherLocalDataSource local;
    late MockLogMessages logger;
    late WeatherRepositoryImpl repository;

    setUp(() {
      remote = MockWeatherRemoteDataSource();
      local = MockWeatherLocalDataSource();
      logger = MockLogMessages();
      repository = WeatherRepositoryImpl(
        remoteDataSource: remote,
        localDataSource: local,
        logMessages: logger,
      );
      when(
        local.read(key: anyNamed('key'), now: anyNamed('now')),
      ).thenAnswer((_) async => null);
      when(
        local.save(
          key: anyNamed('key'),
          json: anyNamed('json'),
          fetchedAt: anyNamed('fetchedAt'),
        ),
      ).thenAnswer((_) async {});
      when(
        remote.fetchForecast(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        ),
      ).thenAnswer((_) async => openMeteoJson());
    });

    void saved({required Duration age}) =>
        when(local.read(key: anyNamed('key'), now: anyNamed('now'))).thenAnswer(
          (_) async =>
              (json: openMeteoJson(hours: 24), fetchedAt: _now.subtract(age)),
        );

    Forecast forecastOf(Either<Failure, Forecast> result) =>
        result.getOrElse(() => throw StateError('$result'));

    /// The forecast for the place, at [_now].
    Future<Either<Failure, Forecast>> forecastNow() =>
        withClock(Clock.fixed(_now), () => repository.forecastFor(_place));

    test('fetches, keeps and returns a forecast for the place', () async {
      final forecast = forecastOf(await forecastNow());
      expect(forecast.hours, hasLength(48));
      expect(forecast.fetchedAt, _now);
      verify(
        remote.fetchForecast(latitude: 40.71, longitude: -74.01),
      ).called(1);
      verify(
        local.save(
          key: '40.71,-74.01',
          json: anyNamed('json'),
          fetchedAt: _now,
        ),
      ).called(1);
    });

    test('uses a forecast fetched within the hour without asking', () async {
      saved(age: const Duration(minutes: 59));
      final forecast = forecastOf(await forecastNow());
      expect(forecast.hours, hasLength(24));
      verifyNever(
        remote.fetchForecast(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        ),
      );
    });

    test('replaces an older forecast with a new one', () async {
      saved(age: const Duration(hours: 1));
      final forecast = forecastOf(await forecastNow());
      expect(forecast.hours, hasLength(48));
      expect(forecast.fetchedAt, _now);
    });

    test('falls back to the kept forecast when offline', () async {
      saved(age: const Duration(hours: 5));
      when(
        remote.fetchForecast(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        ),
      ).thenThrow(NetworkException(Exception('offline'), StackTrace.current));
      final forecast = forecastOf(await forecastNow());
      expect(forecast.fetchedAt, _now.subtract(const Duration(hours: 5)));
    });

    test('reports offline or a server problem when nothing is kept', () async {
      when(
        remote.fetchForecast(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        ),
      ).thenThrow(NetworkException(Exception('offline'), StackTrace.current));
      expect(
        await forecastNow(),
        const Left<Failure, Forecast>(NetworkFailure()),
      );
      when(
        remote.fetchForecast(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        ),
      ).thenThrow(ServerException(Exception('500'), StackTrace.current));
      expect(
        await forecastNow(),
        const Left<Failure, Forecast>(ServerFailure()),
      );
      when(
        remote.fetchForecast(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
        ),
      ).thenAnswer((_) async => {'unexpected': true});
      expect(
        await forecastNow(),
        const Left<Failure, Forecast>(ServerFailure()),
      );
    });

    test('still returns a fetched forecast it could not keep', () async {
      when(
        local.read(key: anyNamed('key'), now: anyNamed('now')),
      ).thenThrow(CacheException(Exception('closed'), StackTrace.current));
      when(
        local.save(
          key: anyNamed('key'),
          json: anyNamed('json'),
          fetchedAt: anyNamed('fetchedAt'),
        ),
      ).thenThrow(CacheException(Exception('disk full'), StackTrace.current));
      final forecast = forecastOf(await forecastNow());
      expect(forecast.hours, hasLength(48));
    });
  });
}
