import 'package:equatable/equatable.dart';

sealed class Failure extends Equatable {
  const Failure();

  @override
  List<Object?> get props => [];
}

final class CacheFailure extends Failure {
  const CacheFailure();
}

final class ServerFailure extends Failure {
  const ServerFailure();
}

final class NetworkFailure extends Failure {
  const NetworkFailure();
}

/// Why the phone's location could not be read.
enum LocationProblem {
  /// Permission was refused; the system may ask again.
  denied,

  /// Permission was refused and the system will not ask again.
  deniedForever,

  /// Location services are switched off on the phone.
  servicesOff,

  /// The phone could not find its position.
  unavailable,
}

final class LocationFailure extends Failure {
  const LocationFailure(this.problem);
  final LocationProblem problem;

  /// Whether only the phone's settings can solve it.
  bool get needsSettings => problem != LocationProblem.unavailable;

  @override
  List<Object?> get props => [problem];
}

/// Why a photo cannot be used.
enum PhotoProblem {
  /// It could not be chosen or opened.
  unreadable,

  /// It is smaller than YouCam needs.
  tooSmall,

  /// It could not be read, or changed to a format YouCam takes.
  unusable,
}

/// A photo could not be chosen, read or used.
final class PhotoFailure extends Failure {
  const PhotoFailure(this.problem);
  final PhotoProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// Why signing in did not finish.
enum SignInProblem {
  /// The person closed the provider's sheet.
  cancelled,

  /// The provider or the network failed.
  failed,
}

final class SignInFailure extends Failure {
  const SignInFailure(this.problem);
  final SignInProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// Why an outfit could not be made.
enum TryOnProblem {
  /// The try-on failed; trying again may work.
  failed,

  /// The try-on could not use the person's photo.
  photo,

  /// YouCam's units are spent.
  noCredit,

  /// This build cannot make outfits.
  unavailable,
}

final class TryOnFailure extends Failure {
  const TryOnFailure(this.problem);
  final TryOnProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// Why a makeup look could not be made.
enum MakeupProblem {
  /// Making it failed; trying again may work.
  failed,

  /// The face photo could not be used.
  photo,

  /// YouCam's units are spent.
  noCredit,

  /// This build cannot make makeup looks.
  unavailable,
}

final class MakeupFailure extends Failure {
  const MakeupFailure(this.problem);
  final MakeupProblem problem;

  @override
  List<Object?> get props => [problem];
}
