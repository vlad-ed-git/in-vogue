import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';

class GetSavedLocation implements UseCase<UserLocation?, NoParams> {
  const GetSavedLocation(this._repository);
  final LocationRepository _repository;

  @override
  Future<Either<Failure, UserLocation?>> call(NoParams params) =>
      _repository.savedLocation();
}
