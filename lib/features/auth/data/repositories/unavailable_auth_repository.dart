import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';

/// Sign-in before Apple and Google are set up: it never creates an account,
/// it says sign-in is not available.
class UnavailableAuthRepository implements AuthRepository {
  const UnavailableAuthRepository();

  @override
  Future<Either<Failure, Account>> signIn(SignInMethod method) async =>
      const Left(SignInFailure(SignInProblem.unavailable));

  @override
  Future<Either<Failure, Account?>> currentAccount() async => const Right(null);
}
