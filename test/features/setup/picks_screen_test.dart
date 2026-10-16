import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/setup/presentation/screens/picks_screen.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:mocktail/mocktail.dart';

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
  fetchedAt: DateTime.utc(2026, 10, 15, 13),
  isSaved: isSaved,
);

ForecastState _ready({UserLocation place = _newYork, bool isSaved = false}) =>
    ForecastState(
      status: ForecastStatus.ready,
      place: place,
      report: _report(isSaved: isSaved),
    );

Colourway _colourway(String id, String name, int hex) => Colourway(
  id: id,
  name: name,
  hex: hex,
  photoUrl: 'https://cdn.example/$id.jpg',
  productUrl: 'https://shop.example/$id',
);

final _coat = Piece(
  id: 'coat',
  name: 'The Wool Coat',
  category: PieceCategory.outerwear,
  bands: const {WarmthBand.cool},
  colourways: [
    _colourway('coat-camel', 'Camel', 0xFFAB9073),
    _colourway('coat-black', 'Black', 0xFF222122),
  ],
);
final _jeans = Piece(
  id: 'jeans',
  name: 'The Way-High Jean',
  category: PieceCategory.bottom,
  bands: const {WarmthBand.cool},
  colourways: [_colourway('jeans-indigo', 'Indigo', 0xFF29313F)],
);

PicksState _pieces({Set<String> picks = const {}}) => PicksState(
  status: PicksStatus.ready,
  pieces: [_coat, _jeans],
  picks: picks,
);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

Finder _tileOf(String name) =>
    find.ancestor(of: find.text(name), matching: find.byType(ProductTile));

/// Scrolls [finder] into view, then taps it.
Future<void> _tapInView(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  late _MockForecastBloc forecast;
  late _MockPicksBloc picks;
  late int backs;
  late int proceeds;

  setUp(() {
    forecast = _MockForecastBloc();
    picks = _MockPicksBloc();
    backs = 0;
    proceeds = 0;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    ForecastState state, {
    Stream<ForecastState> states = const Stream.empty(),
    PicksState pieces = const PicksState(),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(forecast, states, initialState: state);
    whenListen(picks, const Stream<PicksState>.empty(), initialState: pieces);
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
          imageFor: (_) => testImage,
        ),
      ),
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
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

  testWidgets('shows pieces for the weather to pick from', (tester) async {
    await pumpScreen(tester, _ready(), pieces: _pieces(picks: {'coat-black'}));
    expect(find.text('Pick a few you like'), findsOneWidget);
    expect(
      find.textContaining('on a few pieces for this weather'),
      findsOneWidget,
    );
    expect(find.text('The Wool Coat'), findsOneWidget);
    expect(find.text('The Way-High Jean'), findsOneWidget);
    expect(find.text('Your picks · 1'), findsOneWidget);
    expect(find.byType(CategoryChips), findsNothing);
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('asks for the pieces of the day’s band once it has weather', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      const ForecastState(),
      states: Stream.value(_ready()),
    );
    verify(() => picks.add(const PicksRequested(WarmthBand.cool))).called(1);
  });

  testWidgets('loves the colour shown with the heart', (tester) async {
    await pumpScreen(tester, _ready(), pieces: _pieces());
    await _tapInView(
      tester,
      find.descendant(
        of: _tileOf('The Wool Coat'),
        matching: find.byType(LoveToggle),
      ),
    );
    verify(
      () => picks.add(const PickToggled('coat-camel', loved: true)),
    ).called(1);
  });

  testWidgets('unloves every loved colour of a piece', (tester) async {
    await pumpScreen(
      tester,
      _ready(),
      pieces: _pieces(picks: {'coat-camel', 'coat-black'}),
    );
    await _tapInView(
      tester,
      find.descendant(
        of: _tileOf('The Wool Coat'),
        matching: find.byType(LoveToggle),
      ),
    );
    verify(
      () => picks.add(const PickToggled('coat-camel', loved: false)),
    ).called(1);
    verify(
      () => picks.add(const PickToggled('coat-black', loved: false)),
    ).called(1);
  });

  testWidgets('opens a piece’s colours to love one', (tester) async {
    await pumpScreen(tester, _ready(), pieces: _pieces());
    await _tapInView(tester, find.text('The Way-High Jean'));
    await tester.pumpAndSettle();
    expect(find.byType(ColourSheet), findsOneWidget);
    await tester.tap(find.text('Love this colour'));
    verify(
      () => picks.add(const PickToggled('jeans-indigo', loved: true)),
    ).called(1);
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
      pieces: _pieces(),
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(_button('Proceed'), findsOneWidget);
  });
}
