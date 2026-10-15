import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/setup/presentation/screens/picks_screen.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockForecastBloc extends MockBloc<ForecastEvent, ForecastState>
    implements ForecastBloc {}

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

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

void main() {
  late _MockForecastBloc forecast;
  late int backs;
  late int proceeds;

  setUp(() {
    forecast = _MockForecastBloc();
    backs = 0;
    proceeds = 0;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    ForecastState state, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(
      forecast,
      const Stream<ForecastState>.empty(),
      initialState: state,
    );
    await pumpInVogue(
      tester,
      BlocProvider<ForecastBloc>.value(
        value: forecast,
        child: PicksScreen(onBack: () => backs++, onProceed: () => proceeds++),
      ),
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows tomorrow’s weather at step 3 of 6, then Proceed', (
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
    expect(find.text('Getting your outfit ready…'), findsNothing);
    await tester.tap(_button('Proceed'));
    expect(proceeds, 1);
    handle.dispose();
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
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    expect(_button('Proceed'), findsOneWidget);
  });
}
