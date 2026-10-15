import 'package:dartz/dartz.dart';
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

  void _log(String method, CacheException error) => _logger.logError(
    callerClass: 'PreferencesRepositoryImpl',
    callerMethod: method,
    error: error.cause,
    stackTrace: error.stackTrace,
  );
}
