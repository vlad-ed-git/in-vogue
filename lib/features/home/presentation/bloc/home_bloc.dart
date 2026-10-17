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
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/outfits/domain/usecases/get_day_outfit.dart';
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

/// The person switched to [day]. Never starts a try-on.
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

/// Makes, or follows the making of, [day]'s outfit.
final class _OutfitRequested extends HomeEvent {
  const _OutfitRequested(this.day, this.params);
  final ForecastDay day;
  final MakeOutfitParams params;

  @override
  List<Object?> get props => [day, params];
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

/// No outfit was made for the day, and none is being made.
final class OutfitMissing extends OutfitView {
  const OutfitMissing();
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
    this.days = const {},
  });

  final HomeStatus status;
  final UserLocation? place;

  /// The body photo, shown faded while there is no outfit.
  final String? photo;

  /// The day on screen.
  final ForecastDay selected;
  final Map<ForecastDay, HomeDay> days;

  HomeDay day(ForecastDay day) => days[day] ?? const HomeDay();

  HomeDay get shown => day(selected);

  HomeState withDay(ForecastDay day, HomeDay value) => HomeState(
    status: status,
    place: place,
    photo: photo,
    selected: selected,
    days: {...days, day: value},
  );

  HomeState withSelected(ForecastDay day) => HomeState(
    status: status,
    place: place,
    photo: photo,
    selected: day,
    days: days,
  );

  @override
  List<Object?> get props => [status, place, photo, selected, days];
}

/// Home's two days, today and tomorrow, each with its weather and outfit.
///
/// The day shown by default (today from 06:00 to 08:59 and tomorrow
/// otherwise, or always today when the person chose it)
/// gets its outfit made when it has none; the other day only shows an
/// outfit already made. Choosing an occasion makes that occasion's outfit
/// if it has none. An outfit is never made twice.
class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc({
    required this._getCurrentAccount,
    required this._getSavedLocation,
    required this._getKeptPhoto,
    required this._getWeatherReport,
    required this._getDayOutfit,
    required this._makeOutfit,
    required this._getDefaultDay,
  }) : super(const HomeState()) {
    on<HomeStarted>(_start, transformer: restartable());
    on<HomeDaySelected>(_select);
    on<HomeOccasionChanged>(_changeOccasion, transformer: sequential());
    on<HomeRetried>(_retry, transformer: droppable());
    on<_OutfitRequested>(_follow, transformer: concurrent());
  }

  final GetCurrentAccount _getCurrentAccount;
  final GetSavedLocation _getSavedLocation;
  final GetKeptPhoto _getKeptPhoto;
  final GetWeatherReport _getWeatherReport;
  final GetDayOutfit _getDayOutfit;
  final MakeOutfit _makeOutfit;
  final GetDefaultDay _getDefaultDay;

  String? _accountId;

  /// Makings this bloc follows, by key.
  final _following = <String>{};

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
    // Tomorrow means the morning rule: today from 06:00 to 08:59.
    final first = await _getWeatherReport(
      WeatherReportParams(
        location: place,
        day: preferred == ForecastDay.today ? ForecastDay.today : null,
        occasion: _keptOccasion(null),
      ),
    );
    final shownDay = first.fold(
      (_) => ForecastDay.shownAt(clock.now()),
      (report) => report.day,
    );
    final otherDay = ForecastDay.values.firstWhere((day) => day != shownDay);
    final firstLoad = state.status != HomeStatus.ready;
    emit(
      HomeState(
        status: HomeStatus.ready,
        place: place,
        photo: photo?.path,
        selected: firstLoad ? shownDay : state.selected,
        days: state.days,
      ),
    );
    await _loadDay(emit, shownDay, first, make: true);
    final other = await _getWeatherReport(
      WeatherReportParams(
        location: place,
        day: otherDay,
        occasion: _keptOccasion(otherDay),
      ),
    );
    await _loadDay(emit, otherDay, other, make: false);
  }

  /// The occasion chosen for [day] before, if it is still the same date.
  Occasion? _keptOccasion(ForecastDay? day) {
    final weather = state.days[day ?? state.selected]?.report?.weather;
    if (weather == null) return null;
    final today = clock.now();
    final date = (day ?? state.selected).dateFrom(today);
    return weather.date == date ? weather.occasion : null;
  }

  /// Shows [day]'s weather from [report], then its outfit; makes the
  /// outfit when it has none and [make] is set.
  Future<void> _loadDay(
    Emitter<HomeState> emit,
    ForecastDay day,
    Either<Failure, WeatherReport> report, {
    required bool make,
  }) async {
    final loaded = report.fold<WeatherReport?>((_) => null, (report) => report);
    if (loaded == null) {
      return emit(
        state.withDay(
          day,
          HomeDay(weatherFailed: true, outfit: state.day(day).outfit),
        ),
      );
    }
    final before = state.day(day);
    final same =
        before.report?.weather.date == loaded.weather.date &&
        before.report?.weather.occasion == loaded.weather.occasion;
    emit(
      state.withDay(
        day,
        HomeDay(
          report: loaded,
          outfit: same ? before.outfit : const OutfitLooking(),
        ),
      ),
    );
    if (same &&
        (before.outfit is OutfitShown || before.outfit is OutfitMaking)) {
      return;
    }
    await _resolve(emit, day, make: make);
  }

  /// Looks up [day]'s outfit; makes it when there is none and [make] is
  /// set.
  Future<void> _resolve(
    Emitter<HomeState> emit,
    ForecastDay day, {
    required bool make,
  }) async {
    final accountId = _accountId;
    final report = state.day(day).report;
    if (accountId == null || report == null) return;
    final found = await _getDayOutfit(
      DayOutfitParams(
        accountId: accountId,
        date: report.weather.date,
        occasion: report.weather.occasion,
      ),
    );
    if (state.day(day).report != report) return;
    found.fold(
      (failure) => emit(
        state.withDay(day, state.day(day).withOutfit(OutfitFailed(failure))),
      ),
      (outfit) {
        if (outfit != null) {
          return emit(
            state.withDay(day, state.day(day).withOutfit(OutfitShown(outfit))),
          );
        }
        if (!make) {
          return emit(
            state.withDay(
              day,
              state.day(day).withOutfit(const OutfitMissing()),
            ),
          );
        }
        emit(
          state.withDay(day, state.day(day).withOutfit(const OutfitMaking())),
        );
        add(
          _OutfitRequested(
            day,
            MakeOutfitParams(
              accountId: accountId,
              date: report.weather.date,
              occasion: report.weather.occasion,
              weatherClass: report.weatherClass,
            ),
          ),
        );
      },
    );
  }

  Future<void> _follow(_OutfitRequested event, Emitter<HomeState> emit) async {
    final params = event.params;
    if (!_following.add(params.key)) return;
    try {
      await emit.forEach<TryOnUpdate>(
        _makeOutfit(params),
        onData: (update) {
          final day = state.day(event.day);
          final weather = day.report?.weather;
          // The day may have moved on to another date or occasion.
          if (weather?.date != params.date ||
              weather?.occasion != params.occasion) {
            return state;
          }
          return state.withDay(
            event.day,
            day.withOutfit(switch (update) {
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
    } finally {
      _following.remove(params.key);
    }
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
    await _loadDay(emit, day, report, make: true);
  }

  Future<void> _retry(HomeRetried event, Emitter<HomeState> emit) async {
    final shown = state.shown;
    if (state.status == HomeStatus.failed || shown.report == null) {
      return add(const HomeStarted());
    }
    if (shown.outfit is OutfitFailed) {
      await _resolve(emit, state.selected, make: true);
    }
  }
}
