import 'dart:async';
import 'dart:ui';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

/// Infrastructure error, translated to a [LocationFailure] at the repository.
class LocationException implements Exception {
  const LocationException(this.problem);
  final LocationProblem problem;
}

typedef DevicePosition = ({double latitude, double longitude});

/// A position's town and country; either may be unknown.
typedef DevicePlace = ({String? city, String? countryCode});

/// The phone's position and the place it is in.
abstract interface class LocationDeviceDataSource {
  /// Throws [LocationException]. Asks for permission when it is undecided
  /// and [askPermission] is set.
  Future<DevicePosition> position({required bool askPermission});

  /// Names the place in [languageCode]; unknown parts are null.
  Future<DevicePlace> place({
    required double latitude,
    required double longitude,
    required String languageCode,
  });

  /// Opens the phone settings that solve [problem].
  Future<void> openSettings(LocationProblem problem);
}

/// Geolocator and the platform geocoder, through their public APIs.
class LocationDeviceDataSourceImpl implements LocationDeviceDataSource {
  /// Made on first use, once the platform has registered its geocoder.
  late final Geocoding _geocoding = Geocoding();

  /// How long to wait for a fresh fix before using the last known one.
  static const fixTimeLimit = Duration(seconds: 15);

  @override
  Future<DevicePosition> position({required bool askPermission}) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(LocationProblem.servicesOff);
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied && askPermission) {
      permission = await Geolocator.requestPermission();
    }
    switch (permission) {
      case LocationPermission.deniedForever:
        throw const LocationException(LocationProblem.deniedForever);
      case LocationPermission.denied || LocationPermission.unableToDetermine:
        throw const LocationException(LocationProblem.denied);
      case LocationPermission.whileInUse || LocationPermission.always:
        break;
    }
    try {
      final fix = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: fixTimeLimit,
        ),
      );
      return (latitude: fix.latitude, longitude: fix.longitude);
    } on LocationServiceDisabledException {
      throw const LocationException(LocationProblem.servicesOff);
    } on PermissionDeniedException {
      throw const LocationException(LocationProblem.denied);
    } on Exception {
      final last = await Geolocator.getLastKnownPosition();
      if (last == null) {
        throw const LocationException(LocationProblem.unavailable);
      }
      return (latitude: last.latitude, longitude: last.longitude);
    }
  }

  @override
  Future<DevicePlace> place({
    required double latitude,
    required double longitude,
    required String languageCode,
  }) async {
    try {
      final marks = await _geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
        // Passed per call: the Geocoding constructor ignores its locale.
        locale: Locale(languageCode),
      );
      if (marks.isEmpty) return (city: null, countryCode: null);
      final mark = marks.first;
      final city =
          [
            mark.locality,
            mark.subAdministrativeArea,
            mark.administrativeArea,
          ].firstWhere(
            (name) => name != null && name.isNotEmpty,
            orElse: () => null,
          );
      return (city: city, countryCode: _nonEmpty(mark.isoCountryCode));
    } on Exception {
      return (city: null, countryCode: null);
    }
  }

  static String? _nonEmpty(String? value) =>
      value == null || value.isEmpty ? null : value;

  @override
  Future<void> openSettings(LocationProblem problem) async {
    if (problem == LocationProblem.servicesOff) {
      await Geolocator.openLocationSettings();
    } else {
      await Geolocator.openAppSettings();
    }
  }
}
