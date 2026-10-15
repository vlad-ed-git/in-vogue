import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/tried_on_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/setup/presentation/bloc/first_outfit_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/first_outfit_screen.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockFirstOutfitBloc extends MockBloc<FirstOutfitEvent, FirstOutfitState>
    implements FirstOutfitBloc {}

const _newYork = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);
const _photo = UserPhoto(
  role: PhotoRole.body,
  path: '/app/body-1.jpg',
  revision: 1,
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

FirstOutfitState _state({
  UserLocation location = _newYork,
  Progress weather = Progress.ready,
  WeatherReport? report,
  Progress outfit = Progress.loading,
  TriedOnOutfit? triedOn,
}) => FirstOutfitState(
  location: location,
  photo: _photo,
  weather: weather,
  report: weather == Progress.ready ? report ?? _report() : null,
  outfit: outfit,
  triedOn: triedOn,
);

const _outfit = TriedOnOutfit(
  imagePath: '/app/outfit-1.jpg',
  description: 'You in a camel mac and navy trousers',
  reason: 'A mac for the showers after 2 pm.',
);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

void main() {
  late _MockFirstOutfitBloc bloc;
  late int backs;
  late int nexts;

  setUp(() {
    bloc = _MockFirstOutfitBloc();
    backs = 0;
    nexts = 0;
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    FirstOutfitState state, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(
      bloc,
      const Stream<FirstOutfitState>.empty(),
      initialState: state,
    );
    await pumpInVogue(
      tester,
      BlocProvider<FirstOutfitBloc>.value(
        value: bloc,
        child: FirstOutfitScreen(onBack: () => backs++, onNext: () => nexts++),
      ),
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows tomorrow’s weather at once while the outfit is made', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester, _state());
    expect(find.text('3 / 6'), findsOneWidget);
    expect(find.text('Tomorrow, Fri 16 Oct · New York'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Tomorrow, 54 degrees, Showers after 2 pm, feels like 49.',
      ),
      findsOneWidget,
    );
    expect(find.text('WORKDAY'), findsOneWidget);
    expect(find.text('Getting your outfit ready…'), findsOneWidget);
    expect(_button('Next'), findsNothing);
    expect(find.text('Change'), findsNothing);
    handle.dispose();
  });

  testWidgets('shows Celsius outside the Fahrenheit countries', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(
      tester,
      _state(
        location: const UserLocation(
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

  testWidgets('reveals the outfit with why it suits the day, then Next', (
    tester,
  ) async {
    await pumpScreen(tester, _state(outfit: Progress.ready, triedOn: _outfit));
    expect(find.text('A mac for the showers after 2 pm.'), findsOneWidget);
    expect(find.text('Getting your outfit ready…'), findsNothing);
    await tester.ensureVisible(_button('Next'));
    await tester.tap(_button('Next'));
    expect(nexts, 1);
  });

  testWidgets('says plainly when the try-on failed and tries again', (
    tester,
  ) async {
    await pumpScreen(tester, _state(outfit: Progress.failed));
    expect(
      find.text('We couldn’t dress you this time. Your photo is fine.'),
      findsOneWidget,
    );
    expect(_button('Next'), findsNothing);
    await tester.ensureVisible(_button('Try again'));
    await tester.tap(_button('Try again'));
    verify(() => bloc.add(const FirstOutfitTryOnRetried())).called(1);
  });

  testWidgets('says when there is no weather, with no outfit to wait for', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      _state(weather: Progress.failed, outfit: Progress.loading),
    );
    expect(find.text('We couldn’t get the weather.'), findsOneWidget);
    expect(find.text('Getting your outfit ready…'), findsNothing);
    await tester.tap(_button('Try again'));
    verify(() => bloc.add(const FirstOutfitWeatherRetried())).called(1);
  });

  testWidgets('labels a forecast saved earlier with when it was saved', (
    tester,
  ) async {
    await pumpScreen(tester, _state(report: _report(isSaved: true)));
    expect(
      find.textContaining('Showing the forecast saved on'),
      findsOneWidget,
    );
  });

  testWidgets('goes back', (tester) async {
    await pumpScreen(tester, _state());
    await tester.tap(find.text('Back'));
    expect(backs, 1);
  });

  testWidgets('scrolls on a small phone at 200% text', (tester) async {
    await pumpScreen(
      tester,
      _state(outfit: Progress.ready, triedOn: _outfit),
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(_button('Next'), 100);
    expect(_button('Next'), findsOneWidget);
  });
}
