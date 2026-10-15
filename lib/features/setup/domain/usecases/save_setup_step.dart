import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/repositories/setup_repository.dart';

class SaveSetupStep implements UseCase<SetupStep, SetupStep> {
  const SaveSetupStep(this._repository);
  final SetupRepository _repository;

  @override
  Future<Either<Failure, SetupStep>> call(SetupStep step) =>
      _repository.saveStep(step);
}
