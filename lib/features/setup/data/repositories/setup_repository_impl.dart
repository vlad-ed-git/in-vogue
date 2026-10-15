import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/setup/data/data_sources/setup_local_data_source.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/repositories/setup_repository.dart';

class SetupRepositoryImpl implements SetupRepository {
  SetupRepositoryImpl({
    required SetupLocalDataSource localDataSource,
    required LogMessages logMessages,
  }) : _local = localDataSource,
       _logger = logMessages;

  final SetupLocalDataSource _local;
  final LogMessages _logger;

  @override
  Future<Either<Failure, SetupStep>> getStep() async {
    try {
      return Right(_local.getStep());
    } on CacheException catch (error) {
      _log('getStep', error);
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, SetupStep>> saveStep(SetupStep step) async {
    try {
      await _local.saveStep(step);
      return Right(step);
    } on CacheException catch (error) {
      _log('saveStep', error);
      return const Left(CacheFailure());
    }
  }

  void _log(String method, CacheException error) => _logger.logError(
    callerClass: 'SetupRepositoryImpl',
    callerMethod: method,
    error: error.cause,
    stackTrace: error.stackTrace,
  );
}
