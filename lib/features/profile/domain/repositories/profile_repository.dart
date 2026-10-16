import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

abstract interface class ProfileRepository {
  /// The name the person chose; null before they choose one.
  Future<Either<Failure, String?>> name();

  /// Saves [name] trimmed and returns it.
  Future<Either<Failure, String>> saveName(String name);
}
