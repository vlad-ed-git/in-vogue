import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';

abstract interface class SetupRepository {
  Future<Either<Failure, SetupStep>> getStep();
  Future<Either<Failure, SetupStep>> saveStep(SetupStep step);
}
