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
