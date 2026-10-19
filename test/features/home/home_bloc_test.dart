import 'dart:async';

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
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/services/follow_day.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_default_day.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/wardrobe/domain/usecases/wardrobe_usecases.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/day_bands.dart';
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
final _mild = bandsFor(WarmthBand.mild);

WeatherReport _report(ForecastDay day, Occasion occasion) => WeatherReport(
  day: day,
  weather: DayWeather(
    date: day == ForecastDay.today ? _today : _tomorrow,
    occasion: occasion,
    temperature: 17,
    feelsLike: 16,
    sky: Sky.clear,
  ),
  bands: _mild,
  fetchedAt: DateTime.utc(2026, 10, 16, 14),
  isSaved: false,
);

/// The weather of the day asked for, in its occasion or the day's own.
Future<Either<Failure, WeatherReport>> _forecast(Invocation invocation) async {
  final params = invocation.positionalArguments.first as WeatherReportParams;
  final day = params.day ?? ForecastDay.tomorrow;
  final date = day == ForecastDay.today ? _today : _tomorrow;
  return Right(
    _report(
      day,
      params.occasion ?? params.chosen[date] ?? Occasion.defaultFor(date),
    ),
  );
}

MakeOutfitParams _params(DateTime date, Occasion occasion) => MakeOutfitParams(
  accountId: 'uid-1',
  date: date,
  occasion: occasion,
  bands: _mild,
);

DayOutfit _outfit(DateTime date, Occasion occasion) => DayOutfit(
  outfitId: 'o1',
  date: date,
  occasion: occasion,
  picture: '/support/outfits/uid-1/${date.day}_${occasion.name}.jpg',
);

@GenerateMocks([
  GetCurrentAccount,
  GetSavedLocation,
  GetKeptPhoto,
  GetWeatherReport,
  FollowDay,
  GetDefaultDay,
  WatchWardrobe,
])
void main() {
  late MockGetCurrentAccount account;
  late MockGetSavedLocation location;
  late MockGetKeptPhoto photo;
  late MockGetWeatherReport weather;
  late MockFollowDay followDay;
  late MockGetDefaultDay defaultDay;
  late MockWatchWardrobe wardrobe;
  late StreamController<Either<Failure, List<WardrobeOutfit>>> owned;

  /// The updates of each day followed, by date and occasion; the latest
  /// following of each.
  late Map<(DateTime, Occasion), StreamController<TryOnUpdate>> following;

  HomeBloc buildBloc() => HomeBloc(
    getCurrentAccount: account,
    getSavedLocation: location,
    getKeptPhoto: photo,
    getWeatherReport: weather,
    followDay: followDay,
    getDefaultDay: defaultDay,
    watchWardrobe: wardrobe,
  );

  setUp(() {
    account = MockGetCurrentAccount();
    location = MockGetSavedLocation();
    photo = MockGetKeptPhoto();
    weather = MockGetWeatherReport();
    followDay = MockFollowDay();
    defaultDay = MockGetDefaultDay();
    wardrobe = MockWatchWardrobe();
    owned = StreamController.broadcast();
    when(wardrobe(any)).thenAnswer((_) => owned.stream);
    following = {};
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
    when(weather(any)).thenAnswer(_forecast);
    when(followDay(any)).thenAnswer((invocation) {
      final params = invocation.positionalArguments.first as MakeOutfitParams;
      final updates = StreamController<TryOnUpdate>();
      following[(params.date, params.occasion)] = updates;
      return updates.stream;
    });
  });

  /// Home opened on Friday afternoon, following its days.
  Future<HomeBloc> started() async {
    final bloc = withClock(Clock.fixed(_now), buildBloc);
    addTearDown(bloc.close);
    bloc.add(const HomeStarted());
    await bloc.stream.firstWhere((state) => state.status == HomeStatus.ready);
    await pumpEventQueue();
    return bloc;
  }

  /// [update] on the day of [date] in [occasion], as following it gives.
  Future<void> send(
    DateTime date,
    Occasion occasion,
    TryOnUpdate update,
  ) async {
    following[(date, occasion)]!.add(update);
    await pumpEventQueue();
  }

  List<MakeOutfitParams> followed() =>
      verify(followDay(captureAny)).captured.cast<MakeOutfitParams>();

  test("picks the person's own outfit for each day, tomorrow's other than "
      "today's", () async {
    WardrobeOutfit own(String id, Set<Occasion> occasions) => WardrobeOutfit(
      id: id,
      details: OutfitDetails(
        name: 'Outfit $id',
        colours: const {OutfitColour.navy},
        bands: const {WarmthBand.mild},
        rain: false,
        occasions: occasions,
      ),
      photoUrl: 'https://example.invalid/$id.jpg',
      createdAt: _today,
    );
    final bloc = await started();
    verify(wardrobe('uid-1')).called(1);
    expect(bloc.state.wardrobeFor(ForecastDay.today), isNull);
    owned.add(
      Right([
        own('w1', {Occasion.work}),
        own('w2', {Occasion.casual, Occasion.work}),
        own('w3', {Occasion.goingOut}),
      ]),
    );
    await pumpEventQueue();
    final today = bloc.state.wardrobeFor(ForecastDay.today)!;
    final tomorrow = bloc.state.wardrobeFor(ForecastDay.tomorrow)!;
    // Friday is a workday, Saturday casual.
    expect(today.details.occasions, contains(Occasion.work));
    expect(tomorrow.id, 'w2');
    expect(today.id, isNot(tomorrow.id));
    // Home opening again keeps following the same wardrobe.
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    verifyNever(wardrobe(any));
  });

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

  test('keeps the day the person prefers Home to open on', () async {
    expect((await started()).state.preferred, ForecastDay.tomorrow);
    when(
      defaultDay(any),
    ).thenAnswer((_) async => const Right(ForecastDay.today));
    expect((await started()).state.preferred, ForecastDay.today);
  });

  test('follows both days on opening, the day on screen first', () async {
    final bloc = await started();
    expect(followed(), [
      _params(_tomorrow, Occasion.casual),
      _params(_today, Occasion.work),
    ]);
    expect(bloc.state.day(ForecastDay.tomorrow).outfit, const OutfitLooking());
    expect(bloc.state.day(ForecastDay.today).outfit, const OutfitLooking());
  });

  test(
    "shows each day's making, here or on another phone, then its outfit",
    () async {
      final bloc = await started();
      await send(
        _tomorrow,
        Occasion.casual,
        const TryOnProgress(piece: 1, pieces: 2),
      );
      expect(
        bloc.state.day(ForecastDay.tomorrow).outfit,
        const OutfitMaking(piece: 1, pieces: 2),
      );
      expect(bloc.state.day(ForecastDay.today).outfit, const OutfitLooking());

      await send(
        _today,
        Occasion.work,
        TryOnElsewhere(
          Day(
            date: _today,
            occasion: Occasion.work,
            outfitId: 'o2',
            status: DayStatus.making,
            device: 'phone-b',
            piece: 2,
            pieces: 3,
          ),
        ),
      );
      expect(
        bloc.state.day(ForecastDay.today).outfit,
        const OutfitMaking(piece: 2, pieces: 3),
      );

      await send(
        _tomorrow,
        Occasion.casual,
        TryOnDone(_outfit(_tomorrow, Occasion.casual)),
      );
      expect(
        bloc.state.day(ForecastDay.tomorrow).outfit,
        OutfitShown(_outfit(_tomorrow, Occasion.casual)),
      );
      expect(
        bloc.state.day(ForecastDay.today).outfit,
        const OutfitMaking(piece: 2, pieces: 3),
      );
    },
  );

  test(
    'says why a day could not be made, and makes it again when asked',
    () async {
      final bloc = await started();
      await send(
        _tomorrow,
        Occasion.casual,
        const TryOnFailed(NetworkFailure()),
      );
      expect(bloc.state.shown.outfit, const OutfitFailed(NetworkFailure()));

      bloc.add(const HomeRetried());
      await pumpEventQueue();
      verify(followDay.retry(_params(_tomorrow, Occasion.casual))).called(1);
      await send(
        _tomorrow,
        Occasion.casual,
        const TryOnProgress(piece: 1, pieces: 2),
      );
      expect(bloc.state.shown.outfit, const OutfitMaking(piece: 1, pieces: 2));
    },
  );

  test('makes nothing again when the outfit on screen did not fail', () async {
    final bloc = await started();
    await send(_today, Occasion.work, const TryOnFailed(NetworkFailure()));
    await send(
      _tomorrow,
      Occasion.casual,
      TryOnDone(_outfit(_tomorrow, Occasion.casual)),
    );
    bloc.add(const HomeRetried());
    await pumpEventQueue();
    verifyNever(followDay.retry(any));
  });

  test(
    'opens on today, and follows it first, when the person chose today',
    () async {
      when(
        defaultDay(any),
      ).thenAnswer((_) async => const Right(ForecastDay.today));
      final bloc = await started();
      expect(bloc.state.selected, ForecastDay.today);
      expect(followed(), [
        _params(_today, Occasion.work),
        _params(_tomorrow, Occasion.casual),
      ]);
    },
  );

  test('starts nothing new on switching days', () async {
    final bloc = await started();
    bloc.add(const HomeDaySelected(ForecastDay.today));
    await bloc.stream.firstWhere((s) => s.selected == ForecastDay.today);
    await pumpEventQueue();
    verify(followDay(any)).called(2);
  });

  test('follows the chosen occasion, and leaves the old one', () async {
    final bloc = await started();
    await send(
      _tomorrow,
      Occasion.casual,
      TryOnDone(_outfit(_tomorrow, Occasion.casual)),
    );
    bloc.add(const HomeOccasionChanged(Occasion.goingOut));
    await bloc.stream.firstWhere(
      (state) => state.shown.report?.weather.occasion == Occasion.goingOut,
    );
    await pumpEventQueue();
    expect(bloc.state.shown.outfit, const OutfitLooking());
    expect(following[(_tomorrow, Occasion.casual)]!.hasListener, isFalse);
    expect(followed(), contains(_params(_tomorrow, Occasion.goingOut)));

    await send(
      _tomorrow,
      Occasion.goingOut,
      TryOnDone(_outfit(_tomorrow, Occasion.goingOut)),
    );
    expect(
      bloc.state.shown.outfit,
      OutfitShown(_outfit(_tomorrow, Occasion.goingOut)),
    );
  });

  test('gives each day its own occasion when Home loads again with the '
      'other day selected', () async {
    final bloc = await started();
    bloc.add(const HomeDaySelected(ForecastDay.today));
    await pumpEventQueue();
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    expect(
      bloc.state.day(ForecastDay.tomorrow).report?.weather.occasion,
      Occasion.casual,
      reason: 'Saturday',
    );
    expect(
      bloc.state.day(ForecastDay.today).report?.weather.occasion,
      Occasion.work,
      reason: 'Friday',
    );
  });

  test('keeps the outfits on screen when Home loads again', () async {
    final bloc = await started();
    await send(
      _tomorrow,
      Occasion.casual,
      TryOnDone(_outfit(_tomorrow, Occasion.casual)),
    );
    bloc.add(const HomeStarted());
    await pumpEventQueue();
    expect(
      bloc.state.shown.outfit,
      OutfitShown(_outfit(_tomorrow, Occasion.casual)),
    );
    verify(followDay(any)).called(4);
  });

  test(
    'follows no day without weather, and loads it again on Try again',
    () async {
      var offline = true;
      when(weather(any)).thenAnswer((invocation) async {
        final params =
            invocation.positionalArguments.first as WeatherReportParams;
        if (offline && params.day == ForecastDay.today) {
          return const Left(NetworkFailure());
        }
        return _forecast(invocation);
      });
      final bloc = await started();
      expect(bloc.state.day(ForecastDay.today).weatherFailed, isTrue);
      expect(followed(), [_params(_tomorrow, Occasion.casual)]);

      offline = false;
      bloc
        ..add(const HomeDaySelected(ForecastDay.today))
        ..add(const HomeRetried());
      await pumpEventQueue();
      expect(
        bloc.state.day(ForecastDay.today).report?.weather.occasion,
        Occasion.work,
      );
      expect(followed(), [
        _params(_today, Occasion.work),
        _params(_tomorrow, Occasion.casual),
      ]);
    },
  );

  blocTest<HomeBloc, HomeState>(
    'cannot show Home without an account and a place',
    build: () {
      when(account(any)).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const HomeStarted()),
    expect: () => [const HomeState(status: HomeStatus.failed)],
    verify: (_) => verifyNever(followDay(any)),
  );
}
