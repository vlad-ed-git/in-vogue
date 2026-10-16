import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';

/// The name the person chose; null before they choose one.
class GetProfileName implements UseCase<String?, NoParams> {
  const GetProfileName(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) => _repository.name();
}
