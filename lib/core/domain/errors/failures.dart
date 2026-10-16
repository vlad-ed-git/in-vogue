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

/// A photo could not be chosen or read.
final class PhotoFailure extends Failure {
  const PhotoFailure();
}

/// Why signing in did not finish.
enum SignInProblem {
  /// Sign-in is not set up yet.
  unavailable,

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
