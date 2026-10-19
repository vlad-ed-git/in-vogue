import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/setup/presentation/screens/picks_screen.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/catalog_outfits.dart';
import '../../helpers/pump_in_vogue.dart';

class _MockForecastBloc extends MockBloc<ForecastEvent, ForecastState>
    implements ForecastBloc {}

class _MockPicksBloc extends MockBloc<PicksEvent, PicksState>
    implements PicksBloc {}

const _newYork = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);

WeatherReport _report({bool isSaved = false}) => WeatherReport(
  day: ForecastDay.tomorrow,
  weather: DayWeather(
    date: DateTime.utc(2026, 10, 16),
    occasion: Occasion.work,
    temperature: 12.4,
    feelsLike: 9.6,
    sky: Sky.rain,
    event: WeatherEvent(
      WeatherEventKind.showers,
      WeatherTiming.from,
      DateTime.utc(2026, 10, 16, 14),
    ),
  ),
  weatherClass: const WeatherClass(
    band: WarmthBand.cool,
    precipitation: Precipitation.wet,
    windy: false,
  ),
  fetchedAt: DateTime.utc(2026, 10, 15, 13),
  isSaved: isSaved,
);

ForecastState _ready({UserLocation place = _newYork, bool isSaved = false}) =>
    ForecastState(
      status: ForecastStatus.ready,
      place: place,
      report: _report(isSaved: isSaved),
    );

final _coatLook = outfit(
  'o1',
  sample: true,
  name: 'Camel wool coat, white tee, black jeans',
);
final _knitLook = outfit(
  'o2',
  sample: true,
  name: 'Cream knit, indigo way-high jeans',
);

PicksState _sample({Set<String> picks = const {}}) => PicksState(
  status: PicksStatus.ready,
  outfits: [_coatLook, _knitLook],
  picks: picks,
);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

Finder _tileOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(ProductTile));

/// Scrolls [finder] into view, then taps it.
Future<void> _tapInView(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await pumpWhileLoading(tester);
  await tester.tap(finder);
}

void main() {
  late _MockForecastBloc forecast;
  late _MockPicksBloc picks;
  late int backs;
  late int proceeds;
  late List<CatalogOutfit> opened;

  setUpAll(() => registerFallbackValue(const PicksRequested.sample()));

  setUp(() {
    forecast = _MockForecastBloc();
    picks = _MockPicksBloc();
    backs = 0;
    proceeds = 0;
    opened = [];
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    ForecastState state, {
    Stream<ForecastState> states = const Stream.empty(),
    PicksState outfits = const PicksState(),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(forecast, states, initialState: state);
    whenListen(picks, const Stream<PicksState>.empty(), initialState: outfits);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ForecastBloc>.value(value: forecast),
          BlocProvider<PicksBloc>.value(value: picks),
        ],
        child: PicksScreen(
          onBack: () => backs++,
          onProceed: () => proceeds++,
          onOpen: opened.add,
          imageFor: (_) => testImage,
        ),
      ),
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await pumpWhileLoading(tester);
  }

  testWidgets('shows tomorrow’s weather at step 3 of 6; zero picks proceed', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, _ready());
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.text('Tomorrow, Fri 16 Oct · New York'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Tomorrow, 54 degrees, Showers after 2 pm, feels like 49.',
      ),
      findsOneWidget,
    );
    expect(find.text('WORKDAY'), findsOneWidget);
    expect(find.text('Change'), findsNothing);
    expect(find.text('Your picks · 0'), findsOneWidget);
    await tester.tap(_button('Proceed'));
    expect(proceeds, 1);
    handle.dispose();
  });

  testWidgets('shows the sample outfits to pick from', (tester) async {
    await pumpScreen(tester, _ready(), outfits: _sample(picks: {'o2'}));
    expect(find.text('Pick a few you like'), findsOneWidget);
    expect(find.textContaining('on a few outfits you like'), findsOneWidget);
    expect(
      find.text('Camel wool coat, white tee, black jeans'),
      findsOneWidget,
    );
    expect(find.text('Cream knit, indigo way-high jeans'), findsOneWidget);
    expect(find.text('Your picks · 1'), findsOneWidget);
    expect(find.byType(CategoryChips), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('the weather never changes the outfits shown', (tester) async {
    await pumpScreen(
      tester,
      const ForecastState(),
      states: Stream.value(_ready()),
    );
    verifyNever(() => picks.add(any()));
  });

  testWidgets('loves an outfit with its heart, and unloves it', (tester) async {
    await pumpScreen(tester, _ready(), outfits: _sample(picks: {'o2'}));
    Finder heart(String name) =>
        find.descendant(of: _tileOf(name), matching: find.byType(LoveToggle));
    await _tapInView(tester, heart('Camel wool coat, white tee, black jeans'));
    verify(() => picks.add(const PickToggled('o1', loved: true))).called(1);
    await _tapInView(tester, heart('Cream knit, indigo way-high jeans'));
    verify(() => picks.add(const PickToggled('o2', loved: false))).called(1);
  });

  testWidgets('opens an outfit’s pieces', (tester) async {
    await pumpScreen(tester, _ready(), outfits: _sample());
    await _tapInView(tester, find.text('Cream knit, indigo way-high jeans'));
    expect(opened, [_knitLook]);
  });

  testWidgets('says when the outfits can’t be read, and tries again', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      _ready(),
      outfits: const PicksState(
        status: PicksStatus.failed,
        loadFailure: NetworkFailure(),
      ),
    );
    expect(
      find.text('You’re offline. Please check your connection.'),
      findsOneWidget,
    );
    await tester.tap(_button('Try again'));
    verify(() => picks.add(const PicksRequested.sample())).called(1);
  });

  testWidgets('shows Celsius outside the Fahrenheit countries', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      _ready(
        place: const UserLocation(
          latitude: 51.51,
          longitude: -0.13,
          city: 'London',
          countryCode: 'GB',
        ),
      ),
    );
    expect(
      find.bySemanticsLabel(
        'Tomorrow, 12 degrees, Showers after 2 pm, feels like 10.',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('labels a forecast saved earlier with when it was saved', (
    tester,
  ) async {
    await pumpScreen(tester, _ready(isSaved: true));
    expect(
      find.textContaining('Showing the forecast saved on'),
      findsOneWidget,
    );
  });

  testWidgets('says when there is no weather and tries again', (tester) async {
    await pumpScreen(
      tester,
      const ForecastState(status: ForecastStatus.failed, place: _newYork),
    );
    expect(find.text('We couldn’t get the weather.'), findsOneWidget);
    await tester.tap(_button('Try again'));
    verify(() => forecast.add(const ForecastRequested())).called(1);
  });

  testWidgets('goes back', (tester) async {
    await pumpScreen(tester, _ready());
    await tester.tap(find.text('Back'));
    expect(backs, 1);
  });

  testWidgets('fits a small phone at 200% text', (tester) async {
    await pumpScreen(
      tester,
      _ready(),
      outfits: _sample(),
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(_button('Proceed'), findsOneWidget);
  });
}
