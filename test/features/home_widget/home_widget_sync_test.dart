import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/home_widget/presentation/bloc/home_widget_bloc.dart';
import 'package:in_vogue/features/home_widget/presentation/widgets/home_widget_sync.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockHomeBloc extends MockBloc<HomeEvent, HomeState>
    implements HomeBloc {}

class _MockHomeWidgetBloc extends MockBloc<HomeWidgetEvent, HomeWidgetState>
    implements HomeWidgetBloc {}

final _today = DateTime.utc(2026, 10, 18);
final _tomorrow = DateTime.utc(2026, 10, 19);
const _paris = UserLocation(
  latitude: 48.86,
  longitude: 2.35,
  city: 'Paris',
  countryCode: 'FR',
);

WeatherReport _report(DateTime date, ForecastDay day, Occasion occasion) =>
    WeatherReport(
      day: day,
      weather: DayWeather(
        date: date,
        occasion: occasion,
        temperature: 17,
        feelsLike: 16,
        sky: Sky.clear,
      ),
      weatherClass: const WeatherClass(
        band: WarmthBand.mild,
        precipitation: Precipitation.dry,
        windy: false,
      ),
      fetchedAt: DateTime.utc(2026, 10, 18, 6),
      isSaved: false,
    );

final _outfit = DayOutfit(
  outfit: const Outfit(id: 'o1', signature: 'tee', pieces: [], passes: []),
  date: _today,
  occasion: Occasion.casual,
  cell: 'mild|dry|calm|casual',
  picture: '/support/outfits/uid-1/2026-10-18_casual.jpg',
);

final _ready = HomeState(
  status: HomeStatus.ready,
  place: _paris,
  photo: '/photos/body-1.jpg',
  days: {
    ForecastDay.tomorrow: HomeDay(
      report: _report(_tomorrow, ForecastDay.tomorrow, Occasion.work),
    ),
    ForecastDay.today: HomeDay(
      report: _report(_today, ForecastDay.today, Occasion.casual),
      outfit: OutfitShown(_outfit),
    ),
  },
);

void main() {
  late _MockHomeBloc home;
  late _MockHomeWidgetBloc widget;
  late int homeOpened;

  setUpAll(() => registerFallbackValue(const HomeStarted()));
  setUpAll(
    () => registerFallbackValue(
      const HomeWidgetContentChanged(
        WidgetContent(days: [], preferred: ForecastDay.tomorrow, savedLine: ''),
      ),
    ),
  );

  setUp(() {
    home = _MockHomeBloc();
    widget = _MockHomeWidgetBloc();
    homeOpened = 0;
  });

  Future<void> pump(
    WidgetTester tester,
    Stream<HomeState> states, {
    String language = 'es',
    HomeState initial = const HomeState(),
    Stream<HomeWidgetState> taps = const Stream.empty(),
  }) async {
    whenListen(widget, taps, initialState: const HomeWidgetState());
    whenListen(home, states, initialState: initial);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: home),
          BlocProvider<HomeWidgetBloc>.value(value: widget),
        ],
        child: HomeWidgetSync(
          onOpenHome: (_) => homeOpened++,
          child: const SizedBox(),
        ),
      ),
      locale: Locale(language),
    );
    await tester.pump();
  }

  testWidgets("gives the widget Home's days in the person's language, each "
      'with its picture or the photo waiting for it', (tester) async {
    await pump(tester, Stream.value(_ready));
    final content =
        (verify(() => widget.add(captureAny())).captured.single
                as HomeWidgetContentChanged)
            .content;
    expect(content.preferred, ForecastDay.tomorrow);
    expect([for (final day in content.days) day.date], [_today, _tomorrow]);
    expect(content.days.first.picture, _outfit.picture);
    expect(content.days.first.today, 'Hoy');
    expect(content.days.last.picture, isNull);
    expect(content.days.last.waitingPhoto, '/photos/body-1.jpg');
  });

  testWidgets('gives the widget its words again when the language changes', (
    tester,
  ) async {
    await pump(tester, const Stream.empty(), initial: _ready);
    verifyNever(() => widget.add(any()));
    await pump(tester, const Stream.empty(), initial: _ready, language: 'zh');
    final content =
        (verify(() => widget.add(captureAny())).captured.single
                as HomeWidgetContentChanged)
            .content;
    expect(content.days.first.today, '今天');
  });

  testWidgets('a tap on the widget opens Home on its day and occasion', (
    tester,
  ) async {
    final tap = WidgetTap(date: _tomorrow, occasion: Occasion.goingOut);
    await pump(
      tester,
      const Stream.empty(),
      initial: _ready,
      taps: Stream.value(HomeWidgetState(opened: tap, opens: 1)),
    );
    expect(homeOpened, 1);
    verifyInOrder([
      () => home.add(const HomeDaySelected(ForecastDay.tomorrow)),
      () => home.add(const HomeOccasionChanged(Occasion.goingOut)),
    ]);
  });

  testWidgets('a tap that starts the app waits for Home to be ready', (
    tester,
  ) async {
    final tap = WidgetTap(date: _today, occasion: Occasion.casual);
    final states = StreamController<HomeState>();
    addTearDown(states.close);
    await pump(
      tester,
      states.stream,
      taps: Stream.value(HomeWidgetState(opened: tap, opens: 1)),
    );
    expect(homeOpened, 1);
    verifyNever(() => home.add(any()));
    states.add(_ready);
    await tester.pump();
    verify(() => home.add(const HomeDaySelected(ForecastDay.today))).called(1);
    verifyNever(() => home.add(const HomeOccasionChanged(Occasion.casual)));
  });

  testWidgets('gives the widget nothing until Home is ready', (tester) async {
    await pump(tester, Stream.value(const HomeState()));
    verifyNever(() => widget.add(any()));
  });
}
