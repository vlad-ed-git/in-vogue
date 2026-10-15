import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

/// Opens the system photo picker; null when nothing is chosen.
class ChoosePhoto implements UseCase<String?, NoParams> {
  const ChoosePhoto(this._repository);
  final PhotoRepository _repository;

  @override
  Future<Either<Failure, String?>> call(NoParams params) =>
      _repository.choose();
}
