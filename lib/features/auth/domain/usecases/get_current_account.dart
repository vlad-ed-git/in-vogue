import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/repositories/auth_repository.dart';

/// The signed-in account; null when nobody is signed in.
class GetCurrentAccount implements UseCase<Account?, NoParams> {
  const GetCurrentAccount(this._repository);
  final AuthRepository _repository;

  @override
  Future<Either<Failure, Account?>> call(NoParams params) =>
      _repository.currentAccount();
}
