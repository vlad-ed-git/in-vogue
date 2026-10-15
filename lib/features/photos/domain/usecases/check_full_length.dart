import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

/// Whether the photo at a path shows a person head to toe.
class CheckFullLength implements UseCase<bool, String> {
  const CheckFullLength(this._repository);
  final PhotoRepository _repository;

  @override
  Future<Either<Failure, bool>> call(String path) =>
      _repository.isFullLength(path);
}
