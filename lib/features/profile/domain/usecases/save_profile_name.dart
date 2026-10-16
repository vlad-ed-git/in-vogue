import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';

/// Saves the name the person goes by.
class SaveProfileName implements UseCase<String, String> {
  const SaveProfileName(this._repository);
  final ProfileRepository _repository;

  @override
  Future<Either<Failure, String>> call(String name) =>
      _repository.saveName(name);
}
