import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/preferences/data/data_sources/preferences_local_data_source.dart';
import 'package:in_vogue/features/preferences/domain/repositories/preferences_repository.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  PreferencesRepositoryImpl({
    required PreferencesLocalDataSource localDataSource,
    required LogMessages logMessages,
  }) : _local = localDataSource,
       _logger = logMessages;

  final PreferencesLocalDataSource _local;
  final LogMessages _logger;

  @override
  Future<Either<Failure, SupportedLanguages>> getLanguage() async {
    try {
      return Right(_local.getLanguage());
    } on CacheException catch (error) {
      _log('getLanguage', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, SupportedLanguages>> setLanguage(
    SupportedLanguages language,
  ) async {
    try {
      await _local.setLanguage(language);
      return Right(language);
    } on CacheException catch (error) {
      _log('setLanguage', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, ForecastDay>> defaultDay() async {
    try {
      return Right(_local.getDefaultDay());
    } on CacheException catch (error) {
      _log('defaultDay', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, ForecastDay>> setDefaultDay(ForecastDay day) async {
    try {
      await _local.setDefaultDay(day);
      return Right(day);
    } on CacheException catch (error) {
      _log('setDefaultDay', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Map<DateTime, Occasion>>> occasions() async {
    try {
      return Right(_fromNames(_local.getOccasions()));
    } on CacheException catch (error) {
      _log('occasions', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> setOccasion(
    DateTime date,
    Occasion occasion,
  ) async {
    try {
      final kept = {..._fromNames(_local.getOccasions()), date: occasion};
      await _local.setOccasions({
        for (final MapEntry(:key, :value) in kept.entries)
          key.toIso8601String().substring(0, 10): value.name,
      });
      return const Right(unit);
    } on CacheException catch (error) {
      _log('setOccasion', error);
      return const Left(CacheFailure());
    }
  }

  /// The occasions chosen from today on; a date gone by, or one that can't
  /// be read, is left out.
  static Map<DateTime, Occasion> _fromNames(Map<String, String> names) {
    final now = clock.now();
    final today = DateTime.utc(now.year, now.month, now.day);
    return {
      for (final MapEntry(:key, :value) in names.entries)
        if ((
              DateTime.tryParse('${key}T00:00:00Z'),
              Occasion.values.asNameMap()[value],
            )
            case (final date?, final occasion?) when !date.isBefore(today))
          date: occasion,
    };
  }

  void _log(String method, CacheException error) => _logger.logError(
    callerClass: 'PreferencesRepositoryImpl',
    callerMethod: method,
    error: error.cause,
    stackTrace: error.stackTrace,
  );
}
