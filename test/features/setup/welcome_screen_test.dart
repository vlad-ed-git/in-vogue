import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/welcome_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockLocationBloc extends MockBloc<LocationEvent, LocationState>
    implements LocationBloc {}

class _MockPreferencesBloc extends MockBloc<PreferencesEvent, PreferencesState>
    implements PreferencesBloc {}

const _located = LocationState(
  status: LocationStatus.located,
  location: UserLocation(latitude: 40.71, longitude: -74.01),
);

LocationState _failed(Failure failure) =>
    LocationState(status: LocationStatus.failed, failure: failure);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

void main() {
  late _MockLocationBloc bloc;
  late _MockPreferencesBloc preferences;
  late int located;

  setUpAll(
    () => registerFallbackValue(
      const LanguageChanged(SupportedLanguages.english),
    ),
  );

  setUp(() {
    bloc = _MockLocationBloc();
    preferences = _MockPreferencesBloc();
    whenListen(
      preferences,
      const Stream<PreferencesState>.empty(),
      initialState: const PreferencesState(),
    );
    located = 0;
  });

  Future<void> pumpWelcome(
    WidgetTester tester, {
    LocationState state = const LocationState(),
    Stream<LocationState> states = const Stream.empty(),
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(bloc, states, initialState: state);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<LocationBloc>.value(value: bloc),
          BlocProvider<PreferencesBloc>.value(value: preferences),
        ],
        child: WelcomeScreen(onLocated: () => located++),
      ),
      locale: locale,
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await pumpWhileLoading(tester);
  }

  testWidgets('changes the language from the icon at the top right', (
    tester,
  ) async {
    await pumpWelcome(tester);
    final icon = tester.getRect(find.byIcon(InVogueIcons.language));
    final logo = tester.getRect(find.bySemanticsLabel('In Vogue').first);
    expect(icon.top, logo.top);
    expect(icon.right, logo.right);
    await tester.tap(find.bySemanticsLabel('Language'));
    await pumpWhileLoading(tester);
    await tester.tap(find.text('Español'));
    await pumpWhileLoading(tester);
    verify(
      () => preferences.add(
        any(
          that: isA<LanguageChanged>().having(
            (event) => event.language,
            'language',
            SupportedLanguages.spanish,
          ),
        ),
      ),
    ).called(1);
  });

  testWidgets('shows the In Vogue logo, not a photo', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpWelcome(tester);
    final images = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((box) => box.decoration)
        .whereType<BoxDecoration>()
        .map((decoration) => decoration.image?.image)
        .whereType<AssetImage>()
        .map((image) => image.assetName);
    expect(images, ['assets/images/logo.png']);
    expect(find.bySemanticsLabel('In Vogue'), findsOneWidget);
    expect(find.text('In Vogue'), findsNothing);
    handle.dispose();
  });

  testWidgets('introduces In Vogue and asks for the location', (tester) async {
    await pumpWelcome(tester);
    expect(find.text('Meet tomorrow’s weather in style'), findsOneWidget);
    expect(
      find.text(
        'See yourself in an outfit picked for tomorrow’s weather, '
        'with a link to buy every piece.',
      ),
      findsOneWidget,
    );
    expect(_button('Use my location'), findsOneWidget);
    expect(
      tester.getSemantics(find.text('Meet tomorrow’s weather in style')),
      matchesSemantics(
        label: 'Meet tomorrow’s weather in style',
        isHeader: true,
      ),
    );
  });

  testWidgets('keeps the button above the fold on a 390 × 844 phone', (
    tester,
  ) async {
    await pumpWelcome(tester);
    final button = tester.getRect(_button('Use my location'));
    expect(button.bottom, lessThanOrEqualTo(844));
    expect(button.height, InVogueLayout.controlHeight);
  });

  testWidgets('asks for the location in the screen’s language', (tester) async {
    await pumpWelcome(tester, locale: const Locale('es'));
    await tester.tap(_button('Usar mi ubicación'));
    verify(() => bloc.add(const LocationRequested('es'))).called(1);
  });

  testWidgets('works, with its rule running, while the location is found', (
    tester,
  ) async {
    await pumpWelcome(
      tester,
      state: const LocationState(status: LocationStatus.locating),
    );
    expect(
      tester.widget<InVogueButton>(_button('Use my location')).busy,
      isTrue,
    );
    expect(
      find.descendant(
        of: _button('Use my location'),
        matching: find.byType(RunningRule),
      ),
      findsOneWidget,
    );
  });

  testWidgets('moves on once the location is found', (tester) async {
    await pumpWelcome(tester, states: Stream.value(_located));
    expect(located, 1);
  });

  testWidgets(
    'replaces the button with the location notice when refused, and opens settings',
    (tester) async {
      await pumpWelcome(
        tester,
        state: _failed(const LocationFailure(LocationProblem.deniedForever)),
      );
      expect(
        find.text('In Vogue needs your location for the weather.'),
        findsOneWidget,
      );
      expect(_button('Use my location'), findsNothing);
      await tester.tap(_button('Open settings'));
      verify(() => bloc.add(const LocationSettingsRequested())).called(1);
      expect(located, 0);
    },
  );

  testWidgets('checks again on return from settings', (tester) async {
    await pumpWelcome(
      tester,
      state: _failed(const LocationFailure(LocationProblem.denied)),
    );
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    verify(() => bloc.add(const LocationRechecked('en'))).called(1);
  });

  testWidgets('offers to try again when the position cannot be found', (
    tester,
  ) async {
    await pumpWelcome(
      tester,
      state: _failed(const LocationFailure(LocationProblem.unavailable)),
    );
    expect(find.text('We couldn’t find where you are.'), findsOneWidget);
    await tester.tap(_button('Try again'));
    verify(() => bloc.add(const LocationRequested('en'))).called(1);
  });

  testWidgets('says when the location could not be saved', (tester) async {
    await pumpWelcome(tester, state: _failed(const CacheFailure()));
    expect(
      find.text('We couldn’t save your changes. Please try again.'),
      findsOneWidget,
    );
    expect(_button('Try again'), findsOneWidget);
  });

  testWidgets('speaks Chinese', (tester) async {
    await pumpWelcome(tester, locale: const Locale('zh'));
    expect(find.text('以时尚穿搭，迎接明天的天气'), findsOneWidget);
    expect(_button('使用我的位置'), findsOneWidget);
  });

  testWidgets('scrolls to the button on a small phone at 200% text', (
    tester,
  ) async {
    await pumpWelcome(tester, size: const Size(320, 568), textScale: 2);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(_button('Use my location'), 100);
    expect(_button('Use my location'), findsOneWidget);
  });
}
