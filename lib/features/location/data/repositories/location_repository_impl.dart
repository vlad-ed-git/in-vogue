import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/location/data/data_sources/location_device_data_source.dart';
import 'package:in_vogue/features/location/data/data_sources/location_local_data_source.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  LocationRepositoryImpl({
    required LocationDeviceDataSource deviceDataSource,
    required LocationLocalDataSource localDataSource,
    required LogMessages logMessages,
  }) : _device = deviceDataSource,
       _local = localDataSource,
       _logger = logMessages;

  final LocationDeviceDataSource _device;
  final LocationLocalDataSource _local;
  final LogMessages _logger;

  @override
  Future<Either<Failure, UserLocation>> locate({
    required bool askPermission,
    required String languageCode,
  }) async {
    final DevicePosition position;
    try {
      position = await _device.position(askPermission: askPermission);
    } on LocationException catch (error) {
      return Left(LocationFailure(error.problem));
    }
    final latitude = _coarse(position.latitude);
    final longitude = _coarse(position.longitude);
    final place = await _device.place(
      latitude: latitude,
      longitude: longitude,
      languageCode: languageCode,
    );
    final location = UserLocation(
      latitude: latitude,
      longitude: longitude,
      city: place.city,
      countryCode: place.countryCode,
    );
    try {
      await _local.saveLocation(location);
      return Right(location);
    } on CacheException catch (error) {
      _log('locate', error);
      return const Left(CacheFailure());
    }
  }

  /// Rounds to two decimal places, about a kilometre.
  static double _coarse(double degrees) => (degrees * 100).round() / 100;

  @override
  Future<Either<Failure, UserLocation?>> savedLocation() async {
    try {
      return Right(_local.getLocation());
    } on CacheException catch (error) {
      _log('savedLocation', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> forget() async {
    try {
      await _local.deleteLocation();
      return const Right(unit);
    } on CacheException catch (error) {
      _log('forget', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<void> openSettings(LocationProblem problem) =>
      _device.openSettings(problem);

  void _log(String method, CacheException error) => _logger.logError(
    callerClass: 'LocationRepositoryImpl',
    callerMethod: method,
    error: error.cause,
    stackTrace: error.stackTrace,
  );
}
