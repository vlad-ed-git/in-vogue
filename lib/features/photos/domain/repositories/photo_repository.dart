import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';

abstract interface class PhotoRepository {
  /// Opens the system photo picker and makes the chosen photo ready to be
  /// the [role] photo; null when nothing is chosen.
  Future<Either<Failure, ChosenPhoto?>> choose(PhotoRole role);

  /// Keeps the photo at [path] as the [role] photo, replacing the last one.
  Future<Either<Failure, UserPhoto>> keep(String path, PhotoRole role);

  /// The kept [role] photo; null before the first.
  Future<Either<Failure, UserPhoto?>> kept(PhotoRole role);

  /// Deletes the kept [role] photo from the phone.
  Future<Either<Failure, Unit>> forget(PhotoRole role);
}
