import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/locate_user.dart';
import 'package:in_vogue/features/location/domain/usecases/open_location_settings.dart';

sealed class LocationEvent {
  const LocationEvent();
}

/// Reads the location; one at a time.
sealed class LocationLookup extends LocationEvent {
  const LocationLookup(this.languageCode);

  /// Language of the place name.
  final String languageCode;
}

/// The person asked to use their location.
final class LocationRequested extends LocationLookup {
  const LocationRequested(super.languageCode);
}

/// The app is back in front, perhaps from the phone's settings: reads the
/// location again, without asking, if settings could solve the problem.
final class LocationRechecked extends LocationLookup {
  const LocationRechecked(super.languageCode);
}

/// The person chose to open the phone's settings.
final class LocationSettingsRequested extends LocationEvent {
  const LocationSettingsRequested();
}

enum LocationStatus { initial, locating, located, failed }

class LocationState extends Equatable {
  const LocationState({
    this.status = LocationStatus.initial,
    this.location,
    this.failure,
  });

  final LocationStatus status;
  final UserLocation? location;
  final Failure? failure;

  /// The problem that only the phone's settings can solve, if any.
  LocationProblem? get settingsProblem => switch (failure) {
    final LocationFailure failure when failure.needsSettings => failure.problem,
    _ => null,
  };

  @override
  List<Object?> get props => [status, location, failure];
}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  LocationBloc({required this._locateUser, required this._openLocationSettings})
    : super(const LocationState()) {
    on<LocationLookup>(_lookUp, transformer: droppable());
    on<LocationSettingsRequested>(_openSettings);
  }

  final LocateUser _locateUser;
  final OpenLocationSettings _openLocationSettings;

  Future<void> _lookUp(
    LocationLookup event,
    Emitter<LocationState> emit,
  ) async {
    final asks = event is LocationRequested;
    if (!asks && state.settingsProblem == null) return;
    if (asks) emit(const LocationState(status: LocationStatus.locating));
    final result = await _locateUser(
      LocateParams(askPermission: asks, languageCode: event.languageCode),
    );
    emit(
      result.fold(
        (failure) =>
            LocationState(status: LocationStatus.failed, failure: failure),
        (location) =>
            LocationState(status: LocationStatus.located, location: location),
      ),
    );
  }

  Future<void> _openSettings(
    LocationSettingsRequested event,
    Emitter<LocationState> emit,
  ) async {
    final problem = state.settingsProblem;
    if (problem != null) await _openLocationSettings(problem);
  }
}
