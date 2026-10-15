import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';

sealed class ForecastEvent extends Equatable {
  const ForecastEvent();

  @override
  List<Object?> get props => [];
}

/// Loads the saved place's weather for the day shown; again after a failure.
final class ForecastRequested extends ForecastEvent {
  const ForecastRequested();
}

enum ForecastStatus { loading, ready, failed }

class ForecastState extends Equatable {
  const ForecastState({
    this.status = ForecastStatus.loading,
    this.place,
    this.report,
  });

  final ForecastStatus status;
  final UserLocation? place;
  final WeatherReport? report;

  @override
  List<Object?> get props => [status, place, report];
}

/// The weather of the day on screen at the saved place.
class ForecastBloc extends Bloc<ForecastEvent, ForecastState> {
  ForecastBloc({
    required this._getSavedLocation,
    required this._getWeatherReport,
  }) : super(const ForecastState()) {
    on<ForecastRequested>(_load, transformer: droppable());
  }

  final GetSavedLocation _getSavedLocation;
  final GetWeatherReport _getWeatherReport;

  Future<void> _load(
    ForecastRequested event,
    Emitter<ForecastState> emit,
  ) async {
    if (state.status != ForecastStatus.loading) {
      emit(ForecastState(place: state.place));
    }
    final place = (await _getSavedLocation(
      const NoParams(),
    )).getOrElse(() => null);
    if (place == null) {
      return emit(const ForecastState(status: ForecastStatus.failed));
    }
    final report = await _getWeatherReport(
      WeatherReportParams(location: place),
    );
    emit(
      report.fold(
        (_) => ForecastState(status: ForecastStatus.failed, place: place),
        (report) => ForecastState(
          status: ForecastStatus.ready,
          place: place,
          report: report,
        ),
      ),
    );
  }
}
