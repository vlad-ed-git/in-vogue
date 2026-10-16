import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/outfits/domain/usecases/get_day_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_default_day.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'home_bloc_test.mocks.dart';

/// Friday afternoon: tomorrow, Saturday, is shown by default.
final _now = DateTime(2026, 10, 16, 15);
final _today = DateTime.utc(2026, 10, 16);
final _tomorrow = DateTime.utc(2026, 10, 17);
const _paris = UserLocation(
  latitude: 48.86,
  longitude: 2.35,
  city: 'Paris',
  countryCode: 'FR',
);
const _mild = WeatherClass(
  band: WarmthBand.mild,
  precipitation: Precipitation.dry,
  windy: false,
);

WeatherReport _report(ForecastDay day, Occasion occasion) => WeatherReport(
  day: day,
  weather: DayWeather(
    date: day == ForecastDay.today ? _today : _tomorrow,
    occasion: occasion,
    temperature: 17,
    feelsLike: 16,
    sky: Sky.clear,
  ),
  weatherClass: _mild,
  fetchedAt: DateTime.utc(2026, 10, 16, 14),
  isSaved: false,
);

DayOutfit _outfit(DateTime date, Occasion occasion) => DayOutfit(
  outfit: const Outfit(
    id: 'o1',
    signature: 'jeans+tee',
    pieces: ['everlane:jeans', 'everlane:tee'],
    passes: [],
  ),
  date: date,
  occasion: occasion,
  cell: _mild.cell(occasion),
  picture: '/support/outfits/uid-1/jeans+tee.jpg',
);

@GenerateMocks([
  GetCurrentAccount,
  GetSavedLocation,
  GetKeptPhoto,
  GetWeatherReport,
  GetDayOutfit,
  MakeOutfit,
  GetDefaultDay,
])
void main() {
  late MockGetCurrentAccount account;
  late MockGetSavedLocation location;
  late MockGetKeptPhoto photo;
  late MockGetWeatherReport weather;
  late MockGetDayOutfit dayOutfit;
  late MockMakeOutfit makeOutfit;
  late MockGetDefaultDay defaultDay;

  HomeBloc buildBloc() => HomeBloc(
    getCurrentAccount: account,
    getSavedLocation: location,
    getKeptPhoto: photo,
    getWeatherReport: weather,
    getDayOutfit: dayOutfit,
    makeOutfit: makeOutfit,
    getDefaultDay: defaultDay,
  );

  setUp(() {
    account = MockGetCurrentAccount();
    location = MockGetSavedLocation();
    photo = MockGetKeptPhoto();
    weather = MockGetWeatherReport();
    dayOutfit = MockGetDayOutfit();
    makeOutfit = MockMakeOutfit();
    defaultDay = MockGetDefaultDay();
    when(
      defaultDay(any),
    ).thenAnswer((_) async => const Right(ForecastDay.tomorrow));
    when(
      account(any),
    ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
    when(location(any)).thenAnswer((_) async => const Right(_paris));
    when(photo(PhotoRole.body)).thenAnswer(
      (_) async => const Right(
        UserPhoto(
          role: PhotoRole.body,
          path: '/photos/body-1.jpg',
          revision: 1,
        ),
      ),
    );
    when(weather(any)).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.first as WeatherReportParams;
      final day = params.day ?? ForecastDay.tomorrow;
      final date = day == ForecastDay.today ? _today : _tomorrow;
      return Right(_report(day, params.occasion ?? Occasion.defaultFor(date)));
    });
    when(dayOutfit(any)).thenAnswer((_) async => const Right(null));
    when(makeOutfit(any)).thenAnswer(
      (invocation) => Stream.fromIterable([
        const TryOnProgress(piece: 1, pieces: 2),
        const TryOnProgress(piece: 2, pieces: 2),
        TryOnDone(
          _outfit(
            (invocation.positionalArguments.first as MakeOutfitParams).date,
            (invocation.positionalArguments.first as MakeOutfitParams).occasion,
          ),
        ),
      ]),
    );
  });

  Future<HomeBloc> started() async {
    final bloc = buildBloc();
    addTearDown(bloc.close);
    await withClock(Clock.fixed(_now), () async {
      bloc.add(const HomeStarted());
      await bloc.stream.firstWhere(
        (state) =>
            state.day(ForecastDay.tomorrow).outfit is OutfitShown &&
            state.day(ForecastDay.today).outfit is! OutfitLooking,
      );
    });
    return bloc;
  }

  test('shows both days, tomorrow first, each for its occasion', () async {
    final bloc = await started();
    expect(bloc.state.status, HomeStatus.ready);
    expect(bloc.state.place, _paris);
    expect(bloc.state.photo, '/photos/body-1.jpg');
    expect(bloc.state.selected, ForecastDay.tomorrow);
    expect(
      bloc.state.day(ForecastDay.tomorrow).report?.weather.occasion,
      Occasion.casual,
    );
    expect(
      bloc.state.day(ForecastDay.today).report?.weather.occasion,
      Occasion.work,
    );
  });

  test(
    "makes the shown day's outfit when it has none, with progress",
    () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);
      final views = <OutfitView>[];
      final listening = bloc.stream.listen(
        (state) => views.add(state.day(ForecastDay.tomorrow).outfit),
      );
      addTearDown(listening.cancel);
      await withClock(Clock.fixed(_now), () async {
        bloc.add(const HomeStarted());
        await bloc.stream.firstWhere(
          (state) => state.day(ForecastDay.tomorrow).outfit is OutfitShown,
        );
      });
      expect(
        views.toSet().toList(),
        containsAllInOrder([
          const OutfitMaking(),
          const OutfitMaking(piece: 1, pieces: 2),
          const OutfitMaking(piece: 2, pieces: 2),
          OutfitShown(_outfit(_tomorrow, Occasion.casual)),
        ]),
      );
      final made =
          verify(makeOutfit(captureAny)).captured.single as MakeOutfitParams;
      expect(made.accountId, 'uid-1');
      expect(made.date, _tomorrow);
      expect(made.occasion, Occasion.casual);
      expect(made.cell, 'mild|dry|calm|casual');
    },
  );

  test(
    'opens on today, and makes its outfit, when the person chose today',
    () async {
      when(
        defaultDay(any),
      ).thenAnswer((_) async => const Right(ForecastDay.today));
      final bloc = buildBloc();
      addTearDown(bloc.close);
      await withClock(Clock.fixed(_now), () async {
        bloc.add(const HomeStarted());
        await bloc.stream.firstWhere(
          (state) => state.day(ForecastDay.today).outfit is OutfitShown,
        );
      });
      expect(bloc.state.selected, ForecastDay.today);
      final made =
          verify(makeOutfit(captureAny)).captured.single as MakeOutfitParams;
      expect(made.date, _today);
    },
  );

  test('shows an outfit already made, and makes nothing', () async {
    when(dayOutfit(any)).thenAnswer((invocation) async {
      final params = invocation.positionalArguments.first as DayOutfitParams;
      return Right(_outfit(params.date, params.occasion));
    });
    final bloc = await started();
    expect(
      bloc.state.day(ForecastDay.today).outfit,
      OutfitShown(_outfit(_today, Occasion.work)),
    );
    verifyNever(makeOutfit(any));
  });

  test('never makes an outfit for the other day, even on switching', () async {
    final bloc = await started();
    expect(bloc.state.day(ForecastDay.today).outfit, const OutfitMissing());
    bloc.add(const HomeDaySelected(ForecastDay.today));
    await bloc.stream.firstWhere((s) => s.selected == ForecastDay.today);
    await pumpEventQueue();
    final made = verify(makeOutfit(captureAny)).captured;
    expect(made, hasLength(1));
    expect((made.single as MakeOutfitParams).date, _tomorrow);
  });

  test("makes the chosen occasion's outfit", () async {
    final bloc = await started();
    await withClock(Clock.fixed(_now), () async {
      bloc.add(const HomeOccasionChanged(Occasion.goingOut));
      await bloc.stream.firstWhere(
        (state) =>
            state.shown.report?.weather.occasion == Occasion.goingOut &&
            state.shown.outfit is OutfitShown,
      );
    });
    final made = verify(makeOutfit(captureAny)).captured;
    expect((made.last as MakeOutfitParams).occasion, Occasion.goingOut);
  });

  test('says why the outfit could not be made, and tries again', () async {
    when(
      makeOutfit(any),
    ).thenAnswer((_) => Stream.value(const TryOnFailed(NetworkFailure())));
    final bloc = buildBloc();
    addTearDown(bloc.close);
    await withClock(Clock.fixed(_now), () async {
      bloc.add(const HomeStarted());
      await bloc.stream.firstWhere(
        (state) => state.shown.outfit is OutfitFailed,
      );
      expect(bloc.state.shown.outfit, const OutfitFailed(NetworkFailure()));
      bloc.add(const HomeRetried());
      await bloc.stream.firstWhere(
        (state) => state.shown.outfit is OutfitMaking,
      );
      await bloc.stream.firstWhere(
        (state) => state.shown.outfit is OutfitFailed,
      );
    });
    verify(makeOutfit(any)).called(2);
  });

  blocTest<HomeBloc, HomeState>(
    'cannot show Home without an account and a place',
    build: () {
      when(account(any)).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    expect: () => [const HomeState(status: HomeStatus.failed)],
  );
}
