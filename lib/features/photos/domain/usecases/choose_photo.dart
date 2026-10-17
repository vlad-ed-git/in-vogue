import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

/// Opens the system photo picker and makes the chosen photo ready for its
/// role; null when nothing is chosen.
class ChoosePhoto implements UseCase<ChosenPhoto?, PhotoRole> {
  const ChoosePhoto(this._repository);
  final PhotoRepository _repository;

  @override
  Future<Either<Failure, ChosenPhoto?>> call(PhotoRole role) =>
      _repository.choose(role);
}
