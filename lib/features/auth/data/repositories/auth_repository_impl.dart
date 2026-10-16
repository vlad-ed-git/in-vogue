import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required AuthRemoteDataSource remoteDataSource,
    required LogMessages logMessages,
  }) : _remote = remoteDataSource,
       _logger = logMessages;

  final AuthRemoteDataSource _remote;
  final LogMessages _logger;

  @override
  Future<Either<Failure, Account>> signIn(SignInMethod method) async {
    try {
      return Right(await _remote.signIn(method));
    } on SignInException catch (error) {
      if (error.problem == SignInProblem.failed) {
        _logger.logError(
          callerClass: 'AuthRepositoryImpl',
          callerMethod: 'signIn',
          error: error.cause,
          stackTrace: error.stackTrace,
        );
      }
      return Left(SignInFailure(error.problem));
    } on NetworkException {
      return const Left(NetworkFailure());
    }
  }

  @override
  Future<Either<Failure, Account?>> currentAccount() async =>
      Right(_remote.currentAccount());
}
