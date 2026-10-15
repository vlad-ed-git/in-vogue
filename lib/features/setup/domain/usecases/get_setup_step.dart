import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/repositories/setup_repository.dart';

class GetSetupStep implements UseCase<SetupStep, NoParams> {
  const GetSetupStep(this._repository);
  final SetupRepository _repository;

  @override
  Future<Either<Failure, SetupStep>> call(NoParams params) =>
      _repository.getStep();
}
