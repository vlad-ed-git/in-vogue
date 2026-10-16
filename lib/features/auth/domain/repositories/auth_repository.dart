import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/entities/sign_in_method.dart';

export 'package:in_vogue/features/auth/domain/entities/sign_in_method.dart';

abstract interface class AuthRepository {
  /// Signs in with [method]'s account, creating it on first use.
  Future<Either<Failure, Account>> signIn(SignInMethod method);

  /// The signed-in account; null when nobody is signed in.
  Future<Either<Failure, Account?>> currentAccount();

  /// Signs out of the account and of its provider.
  Future<Either<Failure, Unit>> signOut();
}
