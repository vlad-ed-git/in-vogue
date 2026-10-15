import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';

class OpenLocationSettings implements UseCase<Unit, LocationProblem> {
  const OpenLocationSettings(this._repository);
  final LocationRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(LocationProblem problem) async {
    await _repository.openSettings(problem);
    return const Right(unit);
  }
}
