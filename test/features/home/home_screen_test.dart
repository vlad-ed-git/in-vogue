import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/home/presentation/screens/home_screen.dart';
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

const _newYork = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);
final _tomorrow = DateTime.utc(2026, 10, 17);
const _cell = 'cool|wet|calm|casual';
const _reason = 'A coat over a tee with jeans for a cool, wet day off.';

final _report = WeatherReport(
  day: ForecastDay.tomorrow,
  weather: DayWeather(
    date: _tomorrow,
    occasion: Occasion.casual,
    temperature: 12.4,
    feelsLike: 9.6,
    sky: Sky.rain,
    event: WeatherEvent(
      WeatherEventKind.showers,
      WeatherTiming.from,
      DateTime.utc(2026, 10, 17, 15),
    ),
  ),
  weatherClass: const WeatherClass(
    band: WarmthBand.cool,
    precipitation: Precipitation.wet,
    windy: false,
  ),
  fetchedAt: DateTime.utc(2026, 10, 16, 13),
  isSaved: false,
);

final _outfit = DayOutfit(
  outfit: const Outfit(
    id: 'o1',
    signature: 'coat+jeans+tee',
    pieces: ['everlane:jeans', 'everlane:tee', 'everlane:coat'],
    passes: [],
    reasons: {_cell: _reason},
  ),
  date: _tomorrow,
  occasion: Occasion.casual,
  cell: _cell,
  picture: '/support/outfits/uid-1/coat+jeans+tee.jpg',
);

HomeState _state(OutfitView outfit) => HomeState(
  status: HomeStatus.ready,
  place: _newYork,
  photo: '/photos/body-1.jpg',
  days: {ForecastDay.tomorrow: HomeDay(report: _report, outfit: outfit)},
);

void main() {
  late _MockHomeBloc bloc;
  late List<DayOutfit> shopped;
  late int picks;

  setUpAll(() => registerFallbackValue(const HomeStarted()));

  setUp(() {
    bloc = _MockHomeBloc();
    shopped = [];
    picks = 0;
  });

  Future<void> pumpHome(
    WidgetTester tester,
    HomeState state, {
    Size size = const Size(390, 760),
    double textScale = 1,
  }) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: state);
    await pumpInVogue(
      tester,
      BlocProvider<HomeBloc>.value(
        value: bloc,
        child: HomeScreen(onYourPicks: () => picks++, onShop: shopped.add),
      ),
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pump();
  }

  testWidgets('shows the weather, the person in the outfit, Shop and why', (
    tester,
  ) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    expect(find.text('New York'), findsOneWidget);
    expect(find.text('Tomorrow'), findsWidgets);
    final weather = tester.widget<WeatherLine>(find.byType(WeatherLine));
    expect(weather.condition, 'Showers after 3 pm');
    expect(weather.temperature, 54);
    expect(weather.feelsLike, 49);
    final occasion = tester.widget<OccasionLine>(find.byType(OccasionLine));
    expect(occasion.occasion, Occasion.casual);
    expect(occasion.onChange, isNotNull);
    expect(find.text('About this outfit'), findsOneWidget);
    expect(find.text(_reason), findsOneWidget);
    final stage = tester.widget<PhotoStage>(find.byType(PhotoStage));
    expect(stage.state, PhotoStageState.ready);
    expect(stage.outfitLabel, contains(_reason));
    await tester.ensureVisible(find.text('Shop'));
    await tester.tap(find.text('Shop'));
    expect(shopped, [_outfit]);
  });

  testWidgets('keeps the weather, the whole photo and Shop in the first view', (
    tester,
  ) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    await tester.pump();
    final shop = tester.getRect(find.text('Shop'));
    expect(shop.bottom, lessThanOrEqualTo(760));
    final stage = tester.widget<PhotoStage>(find.byType(PhotoStage));
    expect(stage.height, greaterThanOrEqualTo(InVogueLayout.stageMin));
  });

  testWidgets('shows the try-on putting on each piece, and no Shop yet', (
    tester,
  ) async {
    await pumpHome(tester, _state(const OutfitMaking(piece: 2, pieces: 3)));
    expect(find.text('Getting your outfit ready…'), findsOneWidget);
    expect(find.text('Piece 2 of 3'), findsOneWidget);
    expect(find.text('Shop'), findsNothing);
    expect(find.text('About this outfit'), findsNothing);
  });

  testWidgets('says plainly when a day has no outfit', (tester) async {
    await pumpHome(tester, _state(const OutfitMissing()));
    expect(find.text('There’s no outfit for tomorrow.'), findsOneWidget);
    expect(
      tester.widget<PhotoStage>(find.byType(PhotoStage)).state,
      PhotoStageState.idle,
    );
    expect(find.text('Getting your outfit ready…'), findsNothing);
  });

  testWidgets('offers Try again after a failure worth trying again', (
    tester,
  ) async {
    await pumpHome(tester, _state(const OutfitFailed(NetworkFailure())));
    expect(
      find.text('You’re offline. Please check your connection.'),
      findsOneWidget,
    );
    await tester.ensureVisible(find.text('Try again'));
    await tester.tap(find.text('Try again'));
    verify(() => bloc.add(const HomeRetried())).called(1);
  });

  testWidgets('says when the budget is spent, with nothing to retry', (
    tester,
  ) async {
    await pumpHome(
      tester,
      _state(const OutfitFailed(TryOnFailure(TryOnProblem.budgetSpent))),
    );
    expect(find.text('No more outfits can be made for now.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('switches days by tab and by swipe', (tester) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    await tester.tap(find.text('Today'));
    verify(() => bloc.add(const HomeDaySelected(ForecastDay.today))).called(1);
    await tester.fling(find.byType(PhotoStage), const Offset(400, 0), 1000);
    verify(() => bloc.add(const HomeDaySelected(ForecastDay.today))).called(1);
    await tester.fling(find.byType(PhotoStage), const Offset(-400, 0), 1000);
    verify(
      () => bloc.add(const HomeDaySelected(ForecastDay.tomorrow)),
    ).called(1);
  });

  testWidgets('opens Your picks', (tester) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    await tester.tap(find.text('Your picks'));
    expect(picks, 1);
  });

  testWidgets('never shows a price', (tester) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    expect(find.textContaining(r'$'), findsNothing);
    expect(find.textContaining('€'), findsNothing);
  });

  testWidgets('scrolls on a small phone at 200% text', (tester) async {
    await pumpHome(
      tester,
      _state(OutfitShown(_outfit)),
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Shop'));
    expect(find.text('Shop'), findsOneWidget);
  });
}
