import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';

abstract interface class LocationRepository {
  /// Finds, names in [languageCode] and saves the phone's location to about
  /// a kilometre. Asks for permission first when [askPermission] is set.
  Future<Either<Failure, UserLocation>> locate({
    required bool askPermission,
    required String languageCode,
  });

  /// The last saved location; null before the first.
  Future<Either<Failure, UserLocation?>> savedLocation();

  /// Forgets the saved location.
  Future<Either<Failure, Unit>> forget();

  /// Opens the phone settings that solve [problem].
  Future<void> openSettings(LocationProblem problem);
}
