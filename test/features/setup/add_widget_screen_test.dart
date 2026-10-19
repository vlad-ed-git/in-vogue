import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/home_widget/data/repositories/unavailable_home_widget_repository.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/add_widget_screen.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';

import '../../helpers/day_bands.dart';
import '../../helpers/pump_in_vogue.dart';

class _MockForecastBloc extends MockBloc<ForecastEvent, ForecastState>
    implements ForecastBloc {}

class _MockPhotoBloc extends MockBloc<PhotoEvent, PhotoState>
    implements PhotoBloc {}

final _ready = ForecastState(
  status: ForecastStatus.ready,
  place: const UserLocation(
    latitude: 40.71,
    longitude: -74.01,
    city: 'New York',
    countryCode: 'US',
  ),
  report: WeatherReport(
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
    bands: bandsFor(WarmthBand.cool, rain: true),
    fetchedAt: DateTime.utc(2026, 10, 15, 13),
    isSaved: false,
  ),
);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

Future<void> _tapInView(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void main() {
  late _MockForecastBloc forecast;
  late _MockPhotoBloc photo;
  late int backs;
  late int finishes;
  late int pins;

  setUp(() {
    forecast = _MockForecastBloc();
    photo = _MockPhotoBloc();
    backs = 0;
    finishes = 0;
    pins = 0;
    whenListen(
      photo,
      const Stream<PhotoState>.empty(),
      initialState: const PhotoState(
        status: PhotoStatus.chosen,
        path: '/app/body-1.jpg',
        isKept: true,
      ),
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.iOS,
    Future<bool> Function()? onAddWidget,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(
      forecast,
      const Stream<ForecastState>.empty(),
      initialState: _ready,
    );
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ForecastBloc>.value(value: forecast),
          BlocProvider<PhotoBloc>.value(value: photo),
        ],
        child: AddWidgetScreen(
          onBack: () => backs++,
          onFinish: () => finishes++,
          onAddWidget:
              onAddWidget ??
              () async {
                pins++;
                return const UnavailableHomeWidgetRepository().requestPin();
              },
        ),
      ),
      platform: platform,
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the widget with tomorrow’s weather at step 6 of 6', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpScreen(tester);
    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('Add In Vogue to your home screen'), findsOneWidget);
    final preview = tester.widget<HomeWidgetPreview>(
      find.byType(HomeWidgetPreview),
    );
    expect(preview.size, HomeWidgetSize.large);
    expect(preview.temperature, 54);
    expect(preview.feelsLike, 49);
    expect(preview.condition, 'Showers after 2 pm');
    expect(preview.dateLine, 'Fri 16 Oct · Workday');
    expect(preview.waitingPhoto, isNotNull);
    expect(preview.portrait, isNull);
    expect(tester.getSize(find.byType(HomeWidgetPreview)).width, 390);
    expect(
      preview.semanticLabel,
      'Tomorrow, 54 degrees, Showers after 2 pm, feels like 49. '
      'Your outfit is getting ready.',
    );
    handle.dispose();
  });

  testWidgets('on iPhone, shows the three steps and Done', (tester) async {
    await pumpScreen(tester);
    expect(find.text('Three steps on iPhone'), findsOneWidget);
    expect(find.text('Press and hold your home screen'), findsOneWidget);
    expect(find.text('Add to home screen'), findsNothing);
    await _tapInView(tester, _button('Done'));
    expect(finishes, 1);
    expect(pins, 0);
  });

  testWidgets('on Android, asks the launcher, or says how to add it where '
      "the launcher can't", (tester) async {
    await pumpScreen(tester, platform: TargetPlatform.android);
    expect(find.text('Three steps on iPhone'), findsNothing);
    await _tapInView(tester, _button('Add to home screen'));
    expect(pins, 1);
    expect(
      find.text(
        'Add it from your home screen: press and hold, tap Widgets, '
        'choose In Vogue.',
      ),
      findsOneWidget,
    );
    expect(finishes, 0);
    await _tapInView(tester, findLink('Skip'));
    expect(finishes, 1);
  });

  testWidgets('on Android, finishes once the widget is placed', (tester) async {
    await pumpScreen(
      tester,
      platform: TargetPlatform.android,
      onAddWidget: () async => true,
    );
    await _tapInView(tester, _button('Add to home screen'));
    expect(finishes, 1);
  });

  testWidgets('goes back', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Back'));
    expect(backs, 1);
  });

  testWidgets('fits a small phone at 200% text', (tester) async {
    await pumpScreen(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
