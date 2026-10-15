import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/location/data/data_sources/location_device_data_source.dart';
import 'package:in_vogue/features/location/data/data_sources/location_local_data_source.dart';
import 'package:in_vogue/features/location/data/repositories/location_repository_impl.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/memory_store.dart';
import 'location_repository_test.mocks.dart';

const _newYork = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);

@GenerateMocks([
  LocationDeviceDataSource,
  LocationLocalDataSource,
  LocationRepository,
  LogMessages,
])
void main() {
  group('LocationLocalDataSourceImpl', () {
    test('saves the location and reads it back', () async {
      final store = MemoryStore();
      final source = LocationLocalDataSourceImpl(store);
      expect(source.getLocation(), isNull);
      await source.saveLocation(_newYork);
      expect(source.getLocation(), _newYork);
      expect(LocationLocalDataSourceImpl(store).getLocation(), _newYork);
    });

    test('keeps an unknown city and country unknown', () async {
      final store = MemoryStore();
      final source = LocationLocalDataSourceImpl(store);
      const somewhere = UserLocation(latitude: 1.5, longitude: -2);
      await source.saveLocation(somewhere);
      expect(source.getLocation(), somewhere);
    });

    test('has no location when the saved value is unreadable', () {
      final store = MemoryStore()..values['location'] = '{"latitude":"x"}';
      expect(LocationLocalDataSourceImpl(store).getLocation(), isNull);
      store.values['location'] = 'not json';
      expect(LocationLocalDataSourceImpl(store).getLocation(), isNull);
    });
  });

  group('LocationRepositoryImpl', () {
    late MockLocationDeviceDataSource device;
    late MockLocationLocalDataSource local;
    late MockLogMessages logger;
    late LocationRepositoryImpl repository;

    setUp(() {
      device = MockLocationDeviceDataSource();
      local = MockLocationLocalDataSource();
      logger = MockLogMessages();
      repository = LocationRepositoryImpl(
        deviceDataSource: device,
        localDataSource: local,
        logMessages: logger,
      );
      when(
        device.position(askPermission: anyNamed('askPermission')),
      ).thenAnswer((_) async => (latitude: 40.712776, longitude: -74.005974));
      when(
        device.place(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => (city: 'New York', countryCode: 'US'));
      when(local.saveLocation(any)).thenAnswer((_) async {});
    });

    test('names and saves the position to about a kilometre', () async {
      expect(
        await repository.locate(askPermission: true, languageCode: 'en'),
        const Right<Failure, UserLocation>(_newYork),
      );
      verify(device.position(askPermission: true)).called(1);
      verify(
        device.place(latitude: 40.71, longitude: -74.01, languageCode: 'en'),
      ).called(1);
      verify(local.saveLocation(_newYork)).called(1);
    });

    test('keeps a position whose place is unknown', () async {
      when(
        device.place(
          latitude: anyNamed('latitude'),
          longitude: anyNamed('longitude'),
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer((_) async => (city: null, countryCode: null));
      expect(
        await repository.locate(askPermission: false, languageCode: 'zh'),
        const Right<Failure, UserLocation>(
          UserLocation(latitude: 40.71, longitude: -74.01),
        ),
      );
    });

    test('reports why the phone could not locate and saves nothing', () async {
      when(
        device.position(askPermission: anyNamed('askPermission')),
      ).thenThrow(const LocationException(LocationProblem.deniedForever));
      expect(
        await repository.locate(askPermission: true, languageCode: 'en'),
        const Left<Failure, UserLocation>(
          LocationFailure(LocationProblem.deniedForever),
        ),
      );
      verifyNever(local.saveLocation(any));
    });

    test('maps a failed save to a cache failure and logs it', () async {
      final error = CacheException(Exception('disk full'), StackTrace.current);
      when(local.saveLocation(any)).thenThrow(error);
      expect(
        await repository.locate(askPermission: true, languageCode: 'en'),
        const Left<Failure, UserLocation>(CacheFailure()),
      );
      verify(
        logger.logError(
          callerClass: 'LocationRepositoryImpl',
          callerMethod: 'locate',
          error: error.cause,
          stackTrace: error.stackTrace,
        ),
      ).called(1);
    });

    test('returns the saved location or none', () async {
      when(local.getLocation()).thenReturn(_newYork);
      expect(
        await repository.savedLocation(),
        const Right<Failure, UserLocation?>(_newYork),
      );
      when(local.getLocation()).thenReturn(null);
      expect(
        await repository.savedLocation(),
        const Right<Failure, UserLocation?>(null),
      );
    });

    test('maps a failed read to a cache failure', () async {
      when(
        local.getLocation(),
      ).thenThrow(CacheException(Exception('closed'), StackTrace.current));
      expect(
        await repository.savedLocation(),
        const Left<Failure, UserLocation?>(CacheFailure()),
      );
    });

    test('opens the settings that solve a problem', () async {
      when(device.openSettings(any)).thenAnswer((_) async {});
      await repository.openSettings(LocationProblem.servicesOff);
      verify(device.openSettings(LocationProblem.servicesOff)).called(1);
    });
  });
}
