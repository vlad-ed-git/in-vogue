import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_local_data_source.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:in_vogue/features/weather/data/models/open_meteo_forecast_model.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/repositories/weather_repository.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  WeatherRepositoryImpl({
    required WeatherRemoteDataSource remoteDataSource,
    required WeatherLocalDataSource localDataSource,
    required LogMessages logMessages,
    this._clock = const Clock(),
  }) : _remote = remoteDataSource,
       _local = localDataSource,
       _logger = logMessages;

  final WeatherRemoteDataSource _remote;
  final WeatherLocalDataSource _local;
  final LogMessages _logger;
  final Clock _clock;

  @override
  Future<Either<Failure, Forecast>> forecastFor(UserLocation location) async {
    final now = _clock.now().toUtc();
    final key = '${location.latitude},${location.longitude}';
    final kept = await _readKept(key, now);
    if (kept != null &&
        now.difference(kept.fetchedAt) < WeatherRepository.freshFor) {
      return Right(kept);
    }
    final Failure failure;
    try {
      final json = await _remote.fetchForecast(
        latitude: location.latitude,
        longitude: location.longitude,
      );
      final forecast = OpenMeteoForecastModel.fromJson(json, fetchedAt: now);
      await _keep(key, json, now);
      return Right(forecast);
    } on NetworkException catch (error) {
      _log(error.cause, error.stackTrace);
      failure = const NetworkFailure();
    } on ServerException catch (error) {
      _log(error.cause, error.stackTrace);
      failure = const ServerFailure();
    } on FormatException catch (error, stack) {
      _log(error, stack);
      failure = const ServerFailure();
    }
    return kept == null ? Left(failure) : Right(kept);
  }

  Future<Forecast?> _readKept(String key, DateTime now) async {
    try {
      final kept = await _local.read(key: key, now: now);
      if (kept == null) return null;
      return OpenMeteoForecastModel.fromJson(
        kept.json,
        fetchedAt: kept.fetchedAt,
      );
    } on CacheException catch (error) {
      _log(error.cause, error.stackTrace);
      return null;
    } on FormatException {
      return null;
    }
  }

  /// A forecast that cannot be kept is still shown.
  Future<void> _keep(
    String key,
    Map<String, Object?> json,
    DateTime fetchedAt,
  ) async {
    try {
      await _local.save(key: key, json: json, fetchedAt: fetchedAt);
    } on CacheException catch (error) {
      _log(error.cause, error.stackTrace);
    }
  }

  void _log(Object error, StackTrace stackTrace) => _logger.logError(
    callerClass: 'WeatherRepositoryImpl',
    callerMethod: 'forecastFor',
    error: error,
    stackTrace: stackTrace,
  );
}
