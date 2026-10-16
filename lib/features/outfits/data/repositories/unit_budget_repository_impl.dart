import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/data_sources/unit_budget_remote_data_source.dart';
import 'package:in_vogue/features/outfits/domain/repositories/unit_budget_repository.dart';

class UnitBudgetRepositoryImpl implements UnitBudgetRepository {
  UnitBudgetRepositoryImpl({
    required UnitBudgetRemoteDataSource remoteDataSource,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _logger = logMessages;

  final UnitBudgetRemoteDataSource _remote;
  final LogMessages _logger;

  /// How long a call may take before it counts as offline.
  static const timeLimit = Duration(seconds: 20);

  @override
  Future<Either<Failure, Unit>> reserve(int units) => _guard(
    'reserve',
    () async => await _remote.reserve(units)
        ? const Right(unit)
        : const Left(TryOnFailure(TryOnProblem.budgetSpent)),
  );

  @override
  Future<Either<Failure, Unit>> release(int units) =>
      _guard('release', () async {
        await _remote.release(units);
        return const Right(unit);
      });

  Future<Either<Failure, Unit>> _guard(
    String method,
    Future<Either<Failure, Unit>> Function() call,
  ) async {
    try {
      return await call().timeout(timeLimit);
    } on TimeoutException catch (error, stack) {
      _log(method, error, stack);
      return const Left(NetworkFailure());
    } on NetworkException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(NetworkFailure());
    } on ServerException catch (error) {
      _log(method, error.cause, error.stackTrace);
      return const Left(ServerFailure());
    }
  }

  void _log(String method, Object error, StackTrace stackTrace) =>
      _logger.logError(
        callerClass: 'UnitBudgetRepositoryImpl',
        callerMethod: method,
        error: error,
        stackTrace: stackTrace,
      );
}
