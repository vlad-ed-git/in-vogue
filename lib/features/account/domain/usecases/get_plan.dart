import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/repositories/account_repository.dart';

/// The plan of the account with the given id; null before it is saved.
class GetPlan implements UseCase<AccountPlan?, String> {
  const GetPlan(this._repository);
  final AccountRepository _repository;

  @override
  Future<Either<Failure, AccountPlan?>> call(String accountId) =>
      _repository.plan(accountId);
}
