import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
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

class _MockPicksBloc extends MockBloc<PicksEvent, PicksState>
    implements PicksBloc {}

Piece _piece(
  String id,
  String name,
  PieceCategory category,
  Set<WarmthBand> bands, {
  bool waterResistant = false,
}) => Piece(
  id: id,
  name: name,
  category: category,
  bands: bands,
  waterResistant: waterResistant,
  colourways: [
    Colourway(
      id: 'everlane:$id',
      name: 'Black',
      hex: 0xFF111111,
      photoUrl: 'https://cdn.example/$id.jpg',
      productUrl: 'https://www.everlane.com/products/$id',
    ),
  ],
);

final _collection = [
  _piece('mac', 'Oversized Mac Coat', PieceCategory.outerwear, {
    WarmthBand.cool,
    WarmthBand.cold,
  }, waterResistant: true),
  _piece('slip', 'The Satin Slip Dress', PieceCategory.dress, {
    WarmthBand.warm,
    WarmthBand.hot,
  }),
];

const _newYork = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);
final _tomorrow = DateTime.utc(2026, 10, 17);
const _cell = 'cool|wet|calm|casual';
const _reason = 'A coat over a tee with jeans for a cool, wet day off.';
const _razon =
    'Un abrigo sobre una camiseta con jeans para un día libre fresco.';

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
    reasons: {
      _cell: LocalizedText(_reason, translations: {'es': _razon}),
    },
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
  late _MockPicksBloc picksBloc;
  late List<DayOutfit> shopped;
  late int picks;

  setUpAll(() {
    registerFallbackValue(const HomeStarted());
    registerFallbackValue(const PicksRequested(null));
  });

  setUp(() {
    bloc = _MockHomeBloc();
    picksBloc = _MockPicksBloc();
    whenListen(
      picksBloc,
      const Stream<PicksState>.empty(),
      initialState: PicksState(
        status: PicksStatus.ready,
        pieces: _collection,
        picks: const {'everlane:slip'},
      ),
    );
    shopped = [];
    picks = 0;
  });

  Future<void> pumpHome(
    WidgetTester tester,
    HomeState state, {
    Size size = const Size(390, 760),
    double textScale = 1,
    Locale locale = const Locale('en'),
  }) async {
    whenListen(bloc, const Stream<HomeState>.empty(), initialState: state);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<HomeBloc>.value(value: bloc),
          BlocProvider<PicksBloc>.value(value: picksBloc),
        ],
        child: HomeScreen(
          onYourPicks: () => picks++,
          onShop: shopped.add,
          imageFor: (_) => testImage,
        ),
      ),
      size: size,
      textScale: textScale,
      locale: locale,
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
    expect(find.text('About this outfit'), findsOneWidget);
    expect(find.text(_reason), findsOneWidget);
    final stage = tester.widget<PhotoStage>(find.byType(PhotoStage));
    expect(stage.state, PhotoStageState.ready);
    expect(stage.outfitLabel, contains(_reason));
    await tester.ensureVisible(find.text('Shop'));
    await tester.tap(find.text('Shop'));
    expect(shopped, [_outfit]);
  });

  testWidgets("says why in the person's language", (tester) async {
    await pumpHome(
      tester,
      _state(OutfitShown(_outfit)),
      locale: const Locale('es'),
    );
    expect(find.text(_razon), findsOneWidget);
    expect(find.text(_reason), findsNothing);
    final stage = tester.widget<PhotoStage>(find.byType(PhotoStage));
    expect(stage.outfitLabel, contains(_razon));
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
    expect(
      tester.widget<PhotoStage>(find.byType(PhotoStage)).state,
      PhotoStageState.waiting,
    );
    expect(find.byType(RunningRule), findsOneWidget);
    expect(find.text('Shop'), findsNothing);
    expect(find.text('About this outfit'), findsNothing);
  });

  testWidgets('runs the rule over the faded photo while the outfit is '
      'looked up', (tester) async {
    await pumpHome(tester, _state(const OutfitLooking()));
    expect(
      tester.widget<PhotoStage>(find.byType(PhotoStage)).state,
      PhotoStageState.looking,
    );
    expect(find.text('Getting your outfit ready…'), findsNothing);
    expect(find.byType(RunningRule), findsOneWidget);
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

  testWidgets("says when YouCam's units are spent, with nothing to retry", (
    tester,
  ) async {
    await pumpHome(
      tester,
      _state(const OutfitFailed(TryOnFailure(TryOnProblem.noCredit))),
    );
    expect(find.text('No more outfits can be made for now.'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('has Today, Tomorrow and Outfits, by tab and by swipe', (
    tester,
  ) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    expect(tester.widget<DaySwitch>(find.byType(DaySwitch)).labels, [
      'Today',
      'Tomorrow',
      'Outfits',
    ]);
    await tester.tap(find.text('Today'));
    verify(() => bloc.add(const HomeDaySelected(ForecastDay.today))).called(1);
    await tester.fling(find.byType(PhotoStage), const Offset(400, 0), 1000);
    verify(() => bloc.add(const HomeDaySelected(ForecastDay.today))).called(1);
    // Swiping on from tomorrow opens Outfits.
    await tester.fling(find.byType(PhotoStage), const Offset(-400, 0), 1000);
    await tester.pump();
    expect(find.byType(CategoryChips), findsOneWidget);
    verify(() => picksBloc.add(const PicksRequested(null))).called(1);
  });

  testWidgets('moves the weather sideways towards the day chosen', (
    tester,
  ) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    final shift = tester.widget<ShiftSwitcher>(find.byType(ShiftSwitcher));
    expect(shift.direction, 0);
    expect(
      find.descendant(
        of: find.byType(ShiftSwitcher),
        matching: find.byType(WeatherLine),
      ),
      findsOneWidget,
    );
  });

  testWidgets('puts Change below the photo, on the right', (tester) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    final photo = tester.getRect(find.byType(PhotoStage));
    final change = tester.getRect(findLink('Change'));
    expect(change.top, greaterThanOrEqualTo(photo.bottom));
    expect(change.right, closeTo(photo.right, 1));
    expect(
      tester.widget<OccasionLine>(find.byType(OccasionLine)).onChange,
      isNull,
    );
  });

  testWidgets("Outfits opens on the pieces for the day's weather", (
    tester,
  ) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    await tester.tap(find.text('Outfits'));
    await tester.pump();
    expect(find.byType(PhotoStage), findsNothing);
    expect(find.byType(WeatherLine), findsNothing);
    // Tomorrow feels like 9.6 °C: cool, shown in °F in New York.
    expect(
      tester.widget<CategoryChips>(find.byType(CategoryChips)).selectedIndex,
      3,
    );
    expect(find.text('Feels like 46–57°'), findsOneWidget);
    expect(find.text('Oversized Mac Coat'), findsOneWidget);
    expect(find.text('The Satin Slip Dress'), findsNothing);
    await tester.tap(find.bySemanticsLabel('Love Oversized Mac Coat'));
    verify(
      () => picksBloc.add(const PickToggled('everlane:mac', loved: true)),
    ).called(1);
  });

  testWidgets('Outfits groups pieces by weather, rain included', (
    tester,
  ) async {
    await pumpHome(tester, _state(OutfitShown(_outfit)));
    await tester.tap(find.text('Outfits'));
    await tester.pump();
    expect(tester.widget<CategoryChips>(find.byType(CategoryChips)).labels, [
      'Hot',
      'Warm',
      'Mild',
      'Cool',
      'Cold',
      'Freezing',
      'Rain',
    ]);
    await tester.tap(find.text('Warm'));
    await tester.pump();
    expect(find.text('Feels like 68–79°'), findsOneWidget);
    expect(find.text('The Satin Slip Dress'), findsOneWidget);
    expect(find.text('Oversized Mac Coat'), findsNothing);
    await tester.ensureVisible(find.text('Rain'));
    await tester.pump();
    await tester.tap(find.text('Rain'));
    await tester.pump();
    expect(find.text('Water-resistant pieces'), findsOneWidget);
    expect(find.text('Oversized Mac Coat'), findsOneWidget);
    expect(find.text('The Satin Slip Dress'), findsNothing);
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
