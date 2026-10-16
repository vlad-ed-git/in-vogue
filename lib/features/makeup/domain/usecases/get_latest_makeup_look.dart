import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';

/// The look made last for an account; null when none was.
class GetLatestMakeupLook implements UseCase<MakeupLook?, String> {
  const GetLatestMakeupLook(this._repository);
  final MakeupRepository _repository;

  @override
  Future<Either<Failure, MakeupLook?>> call(String accountId) =>
      _repository.latestLook(accountId);
}
