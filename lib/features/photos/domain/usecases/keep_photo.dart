import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';

class KeepPhotoParams extends Equatable {
  const KeepPhotoParams({required this.path, required this.role});

  final String path;
  final PhotoRole role;

  @override
  List<Object?> get props => [path, role];
}

/// Keeps a chosen photo privately, replacing the last one of its role.
class KeepPhoto implements UseCase<UserPhoto, KeepPhotoParams> {
  const KeepPhoto(this._repository);
  final PhotoRepository _repository;

  @override
  Future<Either<Failure, UserPhoto>> call(KeepPhotoParams params) =>
      _repository.keep(params.path, params.role);
}
