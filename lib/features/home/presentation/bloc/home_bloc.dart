import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/services/follow_day.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_default_day.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

/// Loads both days; again when the app comes back to the front.
final class HomeStarted extends HomeEvent {
  const HomeStarted();
}

/// The person switched to [day].
final class HomeDaySelected extends HomeEvent {
  const HomeDaySelected(this.day);
  final ForecastDay day;

  @override
  List<Object?> get props => [day];
}

/// The person chose [occasion] for the day on screen.
final class HomeOccasionChanged extends HomeEvent {
  const HomeOccasionChanged(this.occasion);
  final Occasion occasion;

  @override
  List<Object?> get props => [occasion];
}

/// The person asked to try again for the day on screen.
final class HomeRetried extends HomeEvent {
  const HomeRetried();
}

/// Follows the outfits of [days].
final class _DaysFollowed extends HomeEvent {
  const _DaysFollowed(this.days);
  final Map<ForecastDay, MakeOutfitParams> days;

  @override
  List<Object?> get props => [days];
}

/// What the photo stage shows for a day.
sealed class OutfitView extends Equatable {
  const OutfitView();

  @override
  List<Object?> get props => [];
}

/// The day's outfit is being looked up.
final class OutfitLooking extends OutfitView {
  const OutfitLooking();
}

/// The day's outfit is being made; [piece] of [pieces] is going on, or
/// nothing yet at 0.
final class OutfitMaking extends OutfitView {
  const OutfitMaking({this.piece = 0, this.pieces = 0});
  final int piece;
  final int pieces;

  @override
  List<Object?> get props => [piece, pieces];
}

final class OutfitShown extends OutfitView {
  const OutfitShown(this.outfit);
  final DayOutfit outfit;

  @override
  List<Object?> get props => [outfit];
}

final class OutfitFailed extends OutfitView {
  const OutfitFailed(this.failure);
  final Failure failure;

  @override
  List<Object?> get props => [failure];
}

/// One day on Home: its weather for its occasion, and its outfit.
class HomeDay extends Equatable {
  const HomeDay({
    this.report,
    this.weatherFailed = false,
    this.outfit = const OutfitLooking(),
  });

  /// Holds the date and the occasion.
  final WeatherReport? report;
  final bool weatherFailed;
  final OutfitView outfit;

  HomeDay withOutfit(OutfitView outfit) =>
      HomeDay(report: report, weatherFailed: weatherFailed, outfit: outfit);

  @override
  List<Object?> get props => [report, weatherFailed, outfit];
}

enum HomeStatus { loading, ready, failed }

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeStatus.loading,
    this.place,
    this.photo,
    this.selected = ForecastDay.tomorrow,
    this.preferred = ForecastDay.tomorrow,
    this.days = const {},
  });

  final HomeStatus status;
  final UserLocation? place;

  /// The body photo, shown faded while there is no outfit.
  final String? photo;

  /// The day on screen.
  final ForecastDay selected;

  /// The day Home opens on: tomorrow with the morning rule, or always today.
  final ForecastDay preferred;
  final Map<ForecastDay, HomeDay> days;

  HomeDay day(ForecastDay day) => days[day] ?? const HomeDay();

  HomeDay get shown => day(selected);

  HomeState withDay(ForecastDay day, HomeDay value) => HomeState(
    status: status,
    place: place,
    photo: photo,
    selected: selected,
    preferred: preferred,
    days: {...days, day: value},
  );

  HomeState withSelected(ForecastDay day) => HomeState(
    status: status,
    place: place,
    photo: photo,
    selected: day,
    preferred: preferred,
    days: days,
  );

  @override
  List<Object?> get props => [status, place, photo, selected, preferred, days];
}

/// Home's two days, today and tomorrow, each with its weather and outfit.
///
/// Opens on today from 06:00 to 08:59 and tomorrow otherwise, or always
/// today when the person chose it. Both days' outfits are followed as every
/// phone signed in sees them, and made when they need making.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getCurrentAccount,
    required this._getSavedLocation,
    required this._getKeptPhoto,
    required this._getWeatherReport,
    required this._followDay,
    required this._getDefaultDay,
  }) : super(const HomeState()) {
    on<HomeStarted>(_start, transformer: restartable());
    on<HomeDaySelected>(_select);
    on<HomeOccasionChanged>(_changeOccasion, transformer: sequential());
    on<HomeRetried>(_retry, transformer: droppable());
    on<_DaysFollowed>(_follow, transformer: restartable());
  }

  final GetCurrentAccount _getCurrentAccount;
  final GetSavedLocation _getSavedLocation;
  final GetKeptPhoto _getKeptPhoto;
  final GetWeatherReport _getWeatherReport;
  final FollowDay _followDay;
  final GetDefaultDay _getDefaultDay;

  String? _accountId;

  Future<void> _start(HomeStarted event, Emitter<HomeState> emit) async {
    final account = (await _getCurrentAccount(
      const NoParams(),
    )).fold<Account?>((_) => null, (account) => account);
    final place = (await _getSavedLocation(
      const NoParams(),
    )).fold<UserLocation?>((_) => null, (place) => place);
    if (account == null || place == null) {
      return emit(const HomeState(status: HomeStatus.failed));
    }
    _accountId = account.id;
    final photo = (await _getKeptPhoto(
      PhotoRole.body,
    )).fold<UserPhoto?>((_) => null, (photo) => photo);
    final preferred = (await _getDefaultDay(
      const NoParams(),
    )).getOrElse(() => ForecastDay.tomorrow);
    // Each date keeps the occasion it has on screen; which day comes first
    // is only known once the forecast says what time it is there.
    final chosen = {
      for (final day in state.days.values)
        if (day.report?.weather case final weather?)
          weather.date: weather.occasion,
    };
    // Tomorrow means the morning rule: today from 06:00 to 08:59.
    final first = await _getWeatherReport(
      WeatherReportParams(
        location: place,
        day: preferred == ForecastDay.today ? ForecastDay.today : null,
        chosen: chosen,
      ),
    );
    final shownDay = first.fold(
      (_) => ForecastDay.shownAt(clock.now()),
      (report) => report.day,
    );
    final otherDay = ForecastDay.values.firstWhere((day) => day != shownDay);
    final other = await _getWeatherReport(
      WeatherReportParams(location: place, day: otherDay, chosen: chosen),
    );
    final firstLoad = state.status != HomeStatus.ready;
    var next = HomeState(
      status: HomeStatus.ready,
      place: place,
      photo: photo?.path,
      selected: firstLoad ? shownDay : state.selected,
      preferred: preferred,
      days: state.days,
    );
    for (final (day, report) in [(shownDay, first), (otherDay, other)]) {
      next = next.withDay(day, _loaded(day, report));
    }
    emit(next);
    add(_DaysFollowed(_params()));
  }

  /// [day] with [report]; its outfit view stays when its date and
  /// occasion are the same.
  HomeDay _loaded(ForecastDay day, Either<Failure, WeatherReport> report) {
    final before = state.day(day);
    return report.fold(
      (_) => HomeDay(weatherFailed: true, outfit: before.outfit),
      (loaded) {
        final same =
            before.report?.weather.date == loaded.weather.date &&
            before.report?.weather.occasion == loaded.weather.occasion;
        return HomeDay(
          report: loaded,
          outfit: same ? before.outfit : const OutfitLooking(),
        );
      },
    );
  }

  /// What making each day with weather needs, the day on screen first.
  Map<ForecastDay, MakeOutfitParams> _params() {
    final accountId = _accountId;
    if (accountId == null) return const {};
    return {
      for (final day in [
        state.selected,
        ...ForecastDay.values.where((day) => day != state.selected),
      ])
        if (state.days[day]?.report case final report?)
          day: MakeOutfitParams(
            accountId: accountId,
            date: report.weather.date,
            occasion: report.weather.occasion,
            bands: report.bands,
          ),
    };
  }

  Future<void> _follow(_DaysFollowed event, Emitter<HomeState> emit) =>
      emit.forEach<(ForecastDay, MakeOutfitParams, TryOnUpdate)>(
        _merged(event.days),
        onData: (followed) {
          final (day, params, update) = followed;
          final home = state.day(day);
          final weather = home.report?.weather;
          // The day may have moved on to another date or occasion.
          if (weather?.date != params.date ||
              weather?.occasion != params.occasion) {
            return state;
          }
          return state.withDay(
            day,
            home.withOutfit(switch (update) {
              TryOnProgress(:final piece, :final pieces) => OutfitMaking(
                piece: piece,
                pieces: pieces,
              ),
              TryOnDone(:final outfit) => OutfitShown(outfit),
              TryOnFailed(:final failure) => OutfitFailed(failure),
              TryOnElsewhere(:final day) => OutfitMaking(
                piece: day.piece,
                pieces: day.pieces,
              ),
            }),
          );
        },
      );

  /// Each day's updates, as one stream.
  Stream<(ForecastDay, MakeOutfitParams, TryOnUpdate)> _merged(
    Map<ForecastDay, MakeOutfitParams> days,
  ) {
    final subscriptions = <StreamSubscription<TryOnUpdate>>[];
    late final StreamController<(ForecastDay, MakeOutfitParams, TryOnUpdate)>
    merged;
    merged = StreamController(
      onListen: () {
        for (final MapEntry(key: day, value: params) in days.entries) {
          subscriptions.add(
            _followDay(
              params,
            ).listen((update) => merged.add((day, params, update))),
          );
        }
      },
      onCancel: () =>
          Future.wait([for (final each in subscriptions) each.cancel()]),
    );
    return merged.stream;
  }

  void _select(HomeDaySelected event, Emitter<HomeState> emit) {
    if (event.day != state.selected) emit(state.withSelected(event.day));
  }

  Future<void> _changeOccasion(
    HomeOccasionChanged event,
    Emitter<HomeState> emit,
  ) async {
    final place = state.place;
    final day = state.selected;
    if (place == null ||
        state.shown.report?.weather.occasion == event.occasion) {
      return;
    }
    final report = await _getWeatherReport(
      WeatherReportParams(location: place, day: day, occasion: event.occasion),
    );
    emit(state.withDay(day, _loaded(day, report)));
    add(_DaysFollowed(_params()));
  }

  Future<void> _retry(HomeRetried event, Emitter<HomeState> emit) async {
    final shown = state.shown;
    if (state.status == HomeStatus.failed || shown.report == null) {
      return add(const HomeStarted());
    }
    if (shown.outfit is OutfitFailed) {
      final params = _params()[state.selected];
      if (params != null) _followDay.retry(params);
    }
  }
}
