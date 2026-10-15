import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/tried_on_outfit.dart';
import 'package:in_vogue/features/outfits/domain/usecases/try_on_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';

sealed class FirstOutfitEvent extends Equatable {
  const FirstOutfitEvent();

  @override
  List<Object?> get props => [];
}

/// Shows the weather, then dresses the person.
final class FirstOutfitStarted extends FirstOutfitEvent {
  const FirstOutfitStarted();
}

/// Fetches the weather again, then dresses the person.
final class FirstOutfitWeatherRetried extends FirstOutfitEvent {
  const FirstOutfitWeatherRetried();
}

/// Dresses the person again in the day's outfit.
final class FirstOutfitTryOnRetried extends FirstOutfitEvent {
  const FirstOutfitTryOnRetried();
}

enum Progress { loading, ready, failed }

class FirstOutfitState extends Equatable {
  const FirstOutfitState({
    this.location,
    this.photo,
    this.weather = Progress.loading,
    this.report,
    this.outfit = Progress.loading,
    this.triedOn,
  });

  final UserLocation? location;

  /// The body photo the outfit is tried on.
  final UserPhoto? photo;
  final Progress weather;
  final WeatherReport? report;
  final Progress outfit;
  final TriedOnOutfit? triedOn;

  FirstOutfitState copyWith({
    Progress? weather,
    WeatherReport? report,
    Progress? outfit,
    TriedOnOutfit? triedOn,
  }) => FirstOutfitState(
    location: location,
    photo: photo,
    weather: weather ?? this.weather,
    report: report ?? this.report,
    outfit: outfit ?? this.outfit,
    triedOn: triedOn ?? this.triedOn,
  );

  @override
  List<Object?> get props => [
    location,
    photo,
    weather,
    report,
    outfit,
    triedOn,
  ];
}

/// Setup step 3: the day's weather at once, then the first try-on.
class FirstOutfitBloc extends Bloc<FirstOutfitEvent, FirstOutfitState> {
  FirstOutfitBloc({
    required this._getSavedLocation,
    required this._getKeptPhoto,
    required this._getWeatherReport,
    required this._tryOnOutfit,
  }) : super(const FirstOutfitState()) {
    on<FirstOutfitEvent>(
      (event, emit) => switch (event) {
        FirstOutfitStarted() => _start(emit),
        FirstOutfitWeatherRetried() => _loadWeather(emit),
        FirstOutfitTryOnRetried() => _tryOn(emit),
      },
      transformer: droppable(),
    );
  }

  final GetSavedLocation _getSavedLocation;
  final GetKeptPhoto _getKeptPhoto;
  final GetWeatherReport _getWeatherReport;
  final TryOnOutfit _tryOnOutfit;

  Future<void> _start(Emitter<FirstOutfitState> emit) async {
    final location = await _getSavedLocation(const NoParams());
    final photo = await _getKeptPhoto(PhotoRole.body);
    emit(
      FirstOutfitState(
        location: location.getOrElse(() => null),
        photo: photo.getOrElse(() => null),
      ),
    );
    await _loadWeather(emit);
  }

  Future<void> _loadWeather(Emitter<FirstOutfitState> emit) async {
    final location = state.location;
    if (location == null) return emit(state.copyWith(weather: Progress.failed));
    emit(state.copyWith(weather: Progress.loading, outfit: Progress.loading));
    final report = await _getWeatherReport(
      WeatherReportParams(location: location),
    );
    report.fold(
      (_) => emit(state.copyWith(weather: Progress.failed)),
      (report) => emit(state.copyWith(weather: Progress.ready, report: report)),
    );
    if (state.weather == Progress.ready) await _tryOn(emit);
  }

  Future<void> _tryOn(Emitter<FirstOutfitState> emit) async {
    final report = state.report;
    if (report == null) return;
    final photo = state.photo;
    if (photo == null) return emit(state.copyWith(outfit: Progress.failed));
    emit(state.copyWith(outfit: Progress.loading));
    final outfit = await _tryOnOutfit(
      TryOnParams(photo: photo, weather: report.weather),
    );
    outfit.fold(
      (_) => emit(state.copyWith(outfit: Progress.failed)),
      (outfit) => emit(state.copyWith(outfit: Progress.ready, triedOn: outfit)),
    );
  }
}
