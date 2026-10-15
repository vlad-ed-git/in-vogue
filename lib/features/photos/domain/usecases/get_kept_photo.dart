import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

/// The kept photo of a role; null before the first.
class GetKeptPhoto implements UseCase<UserPhoto?, PhotoRole> {
  const GetKeptPhoto(this._repository);
  final PhotoRepository _repository;

  @override
  Future<Either<Failure, UserPhoto?>> call(PhotoRole role) =>
      _repository.kept(role);
}
