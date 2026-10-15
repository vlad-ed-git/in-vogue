import 'dart:async';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart'
    as pi;
import 'package:geolocator/geolocator.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/data/data_sources/location_device_data_source.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'location_device_data_source_test.mocks.dart' as base;

// The mixin makes the plugins accept the mocks as their platforms.
class _MockGeolocatorPlatform extends base.MockGeolocatorPlatform
    with MockPlatformInterfaceMixin {}

class _MockGeocodingPlatform extends base.MockGeocodingPlatform
    with MockPlatformInterfaceMixin {}

class _MockGeocodingFactory
    with MockPlatformInterfaceMixin
    implements GeocodingPlatformFactory {
  _MockGeocodingFactory(this.geocoding);
  final pi.Geocoding geocoding;

  @override
  pi.Geocoding createGeocoding(pi.GeocodingCreationParams params) => geocoding;
}

Position _position(double latitude, double longitude) => Position(
  latitude: latitude,
  longitude: longitude,
  timestamp: DateTime.utc(2026, 10, 15),
  accuracy: 3000,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

Matcher _problem(LocationProblem problem) => throwsA(
  isA<LocationException>().having((e) => e.problem, 'problem', problem),
);

@GenerateMocks(
  [],
  customMocks: [
    MockSpec<GeolocatorPlatform>(),
    MockSpec<pi.Geocoding>(as: #MockGeocodingPlatform),
  ],
)
void main() {
  late _MockGeolocatorPlatform geolocator;
  late _MockGeocodingPlatform geocoding;
  late LocationDeviceDataSourceImpl source;

  setUp(() {
    final original = GeolocatorPlatform.instance;
    addTearDown(() => GeolocatorPlatform.instance = original);
    GeolocatorPlatform.instance = geolocator = _MockGeolocatorPlatform();
    GeocodingPlatformFactory.instance = _MockGeocodingFactory(
      geocoding = _MockGeocodingPlatform(),
    );
    source = LocationDeviceDataSourceImpl();
    when(geolocator.isLocationServiceEnabled()).thenAnswer((_) async => true);
    when(
      geolocator.checkPermission(),
    ).thenAnswer((_) async => LocationPermission.whileInUse);
    when(
      geolocator.getCurrentPosition(
        locationSettings: anyNamed('locationSettings'),
      ),
    ).thenAnswer((_) async => _position(40.7128, -74.006));
  });

  group('position', () {
    test('asks for permission when it is undecided, then reads it', () async {
      when(
        geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        geolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.whileInUse);
      final position = await source.position(askPermission: true);
      expect(position.latitude, 40.7128);
      expect(position.longitude, -74.006);
      verify(geolocator.requestPermission()).called(1);
    });

    test('asks only for low accuracy, with a time limit', () async {
      await source.position(askPermission: true);
      final settings =
          verify(
                geolocator.getCurrentPosition(
                  locationSettings: captureAnyNamed('locationSettings'),
                ),
              ).captured.single
              as LocationSettings;
      expect(settings.accuracy, LocationAccuracy.low);
      expect(settings.timeLimit, isNotNull);
    });

    test('never asks for permission when asking is not allowed', () async {
      when(
        geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      await expectLater(
        source.position(askPermission: false),
        _problem(LocationProblem.denied),
      );
      verifyNever(geolocator.requestPermission());
    });

    test('reports a refusal and a permanent refusal', () async {
      when(
        geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      when(
        geolocator.requestPermission(),
      ).thenAnswer((_) async => LocationPermission.denied);
      await expectLater(
        source.position(askPermission: true),
        _problem(LocationProblem.denied),
      );
      when(
        geolocator.checkPermission(),
      ).thenAnswer((_) async => LocationPermission.deniedForever);
      await expectLater(
        source.position(askPermission: true),
        _problem(LocationProblem.deniedForever),
      );
    });

    test('reports location services that are switched off', () async {
      when(
        geolocator.isLocationServiceEnabled(),
      ).thenAnswer((_) async => false);
      await expectLater(
        source.position(askPermission: true),
        _problem(LocationProblem.servicesOff),
      );
      verifyNever(geolocator.requestPermission());
    });

    test('uses the last known position when a fix takes too long', () async {
      when(
        geolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        ),
      ).thenThrow(TimeoutException('no fix'));
      when(
        geolocator.getLastKnownPosition(
          forceLocationManager: anyNamed('forceLocationManager'),
        ),
      ).thenAnswer((_) async => _position(51.5072, -0.1276));
      final position = await source.position(askPermission: true);
      expect(position.latitude, 51.5072);
    });

    test('reports an unavailable position when there is none', () async {
      when(
        geolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        ),
      ).thenThrow(TimeoutException('no fix'));
      when(
        geolocator.getLastKnownPosition(
          forceLocationManager: anyNamed('forceLocationManager'),
        ),
      ).thenAnswer((_) async => null);
      await expectLater(
        source.position(askPermission: true),
        _problem(LocationProblem.unavailable),
      );
    });

    test('maps platform errors while reading to their problems', () async {
      when(
        geolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        ),
      ).thenThrow(const LocationServiceDisabledException());
      await expectLater(
        source.position(askPermission: true),
        _problem(LocationProblem.servicesOff),
      );
      when(
        geolocator.getCurrentPosition(
          locationSettings: anyNamed('locationSettings'),
        ),
      ).thenThrow(const PermissionDeniedException('denied'));
      await expectLater(
        source.position(askPermission: true),
        _problem(LocationProblem.denied),
      );
    });
  });

  group('place', () {
    test('names the city and country in the requested language', () async {
      when(
        geocoding.placemarkFromCoordinates(
          40.71,
          -74.01,
          locale: anyNamed('locale'),
        ),
      ).thenAnswer(
        (_) async => [
          const Placemark(
            locality: 'New York',
            administrativeArea: 'NY',
            isoCountryCode: 'US',
          ),
        ],
      );
      final place = await source.place(
        latitude: 40.71,
        longitude: -74.01,
        languageCode: 'es',
      );
      expect(place.city, 'New York');
      expect(place.countryCode, 'US');
      final locale =
          verify(
                geocoding.placemarkFromCoordinates(
                  40.71,
                  -74.01,
                  locale: captureAnyNamed('locale'),
                ),
              ).captured.single
              as Locale;
      expect(locale.languageCode, 'es');
    });

    test('falls back to the wider area when there is no town', () async {
      when(
        geocoding.placemarkFromCoordinates(
          any,
          any,
          locale: anyNamed('locale'),
        ),
      ).thenAnswer(
        (_) async => [
          const Placemark(
            locality: '',
            subAdministrativeArea: 'Kerry',
            isoCountryCode: 'IE',
          ),
        ],
      );
      final place = await source.place(
        latitude: 52.06,
        longitude: -9.5,
        languageCode: 'en',
      );
      expect(place.city, 'Kerry');
    });

    test('knows no place when the geocoder fails or finds nothing', () async {
      when(
        geocoding.placemarkFromCoordinates(
          any,
          any,
          locale: anyNamed('locale'),
        ),
      ).thenThrow(Exception('offline'));
      var place = await source.place(
        latitude: 1,
        longitude: 1,
        languageCode: 'en',
      );
      expect(place.city, isNull);
      expect(place.countryCode, isNull);
      when(
        geocoding.placemarkFromCoordinates(
          any,
          any,
          locale: anyNamed('locale'),
        ),
      ).thenAnswer((_) async => []);
      place = await source.place(latitude: 1, longitude: 1, languageCode: 'en');
      expect(place.city, isNull);
    });
  });

  test('opens app settings or location settings', () async {
    when(geolocator.openAppSettings()).thenAnswer((_) async => true);
    when(geolocator.openLocationSettings()).thenAnswer((_) async => true);
    await source.openSettings(LocationProblem.deniedForever);
    verify(geolocator.openAppSettings()).called(1);
    await source.openSettings(LocationProblem.servicesOff);
    verify(geolocator.openLocationSettings()).called(1);
  });
}
