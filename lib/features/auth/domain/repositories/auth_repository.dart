import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';

/// The only ways to sign in.
enum SignInMethod { apple, google }

abstract interface class AuthRepository {
  /// Signs in with [method]'s account, creating it on first use.
  Future<Either<Failure, Account>> signIn(SignInMethod method);
}
