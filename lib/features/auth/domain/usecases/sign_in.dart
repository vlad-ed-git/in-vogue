import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';

/// Signs in with Apple or Google.
class SignIn implements UseCase<Account, SignInMethod> {
  const SignIn(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, Account>> call(SignInMethod method) =>
      _repository.signIn(method);
}
