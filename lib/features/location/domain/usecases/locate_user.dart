import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/repositories/location_repository.dart';

class LocateParams extends Equatable {
  const LocateParams({required this.askPermission, required this.languageCode});

  /// Whether the system may ask for permission.
  final bool askPermission;

  /// Language of the place name.
  final String languageCode;

  @override
  List<Object?> get props => [askPermission, languageCode];
}

class LocateUser implements UseCase<UserLocation, LocateParams> {
  const LocateUser(this._repository);
  final LocationRepository _repository;

  @override
  Future<Either<Failure, UserLocation>> call(LocateParams params) =>
      _repository.locate(
        askPermission: params.askPermission,
        languageCode: params.languageCode,
      );
}
