import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/app/in_vogue_app.dart';
import 'package:in_vogue/app/router/in_vogue_screens.dart';
import 'package:in_vogue/app/router/tab_shell.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/location/domain/usecases/locate_user.dart';
import 'package:in_vogue/features/location/domain/usecases/open_location_settings.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/check_full_length.dart';
import 'package:in_vogue/features/photos/domain/usecases/choose_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/keep_photo.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_language.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/usecases/save_setup_step.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:mockito/mockito.dart';

import 'features/location/location_repository_test.mocks.dart';
import 'features/photos/photo_repository_test.mocks.dart';
import 'features/preferences/preferences_repository_test.mocks.dart';
import 'features/setup/setup_repository_test.mocks.dart';
import 'features/weather/weather_repository_test.mocks.dart';
import 'helpers/pump_in_vogue.dart';

const _place = UserLocation(latitude: 1, longitude: 2);
const _photo = UserPhoto(
  role: PhotoRole.body,
  path: '/app/body-1.jpg',
  revision: 1,
);

void main() {
  late MockPreferencesRepository preferences;
  late MockSetupRepository setup;
  late MockLocationRepository location;
  late GetIt locator;

  setUp(() {
    preferences = MockPreferencesRepository();
    setup = MockSetupRepository();
    location = MockLocationRepository();
    final photos = MockPhotoRepository();
    when(photos.kept(any)).thenAnswer((_) async => const Right(_photo));
    when(location.savedLocation()).thenAnswer((_) async => const Right(_place));
    final weather = MockWeatherRepository();
    when(
      weather.forecastFor(any),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    locator = GetIt.asNewInstance()
      ..registerFactory<ForecastBloc>(
        () => ForecastBloc(
          getSavedLocation: GetSavedLocation(location),
          getWeatherReport: GetWeatherReport(weather),
        ),
      )
      ..registerFactoryParam<PhotoBloc, PhotoRole, void>(
        (role, _) => PhotoBloc(
          role: role,
          choosePhoto: ChoosePhoto(photos),
          checkFullLength: CheckFullLength(photos),
          keepPhoto: KeepPhoto(photos),
          getKeptPhoto: GetKeptPhoto(photos),
        ),
      )
      ..registerFactory<LocationBloc>(
        () => LocationBloc(
          locateUser: LocateUser(location),
          openLocationSettings: OpenLocationSettings(location),
        ),
      );
    when(setup.saveStep(any)).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as SetupStep),
    );
  });

  InVogueApp app({
    SupportedLanguages language = SupportedLanguages.english,
    SetupStep step = SetupStep.done,
  }) => InVogueApp(
    createPreferencesBloc: () => PreferencesBloc(
      setLanguage: SetLanguage(preferences),
      initialLanguage: language,
    ),
    createSetupBloc: () =>
        SetupBloc(saveSetupStep: SaveSetupStep(setup), initialStep: step),
    screens: inVogueScreens(locator),
  );

  /// Opens Settings from its [tab] label and picks [name] in the language
  /// row titled [row].
  Future<void> chooseLanguage(
    WidgetTester tester, {
    required String tab,
    required String row,
    required String name,
  }) async {
    await tester.tap(find.text(tab));
    await tester.pumpAndSettle();
    final languageRow = find.ancestor(
      of: find.text(row),
      matching: find.byType(SettingsRow),
    );
    await tester.tap(
      find.descendant(of: languageRow, matching: find.byType(TextLink)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  testWidgets('opens setup until it is finished, then the tabs', (
    tester,
  ) async {
    await tester.pumpWidget(app(step: SetupStep.welcome));
    await tester.pumpAndSettle();
    expect(find.byType(InVogueTabBar), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.byType(InVogueTabBar), findsOneWidget);
  });

  testWidgets('moves from Welcome to Your photo once located', (tester) async {
    when(
      location.locate(
        askPermission: anyNamed('askPermission'),
        languageCode: anyNamed('languageCode'),
      ),
    ).thenAnswer((_) async => const Right(_place));
    await tester.pumpWidget(app(step: SetupStep.welcome));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('Add a photo of you'), findsOneWidget);
    verify(setup.saveStep(SetupStep.photo)).called(1);
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Use my location'), findsOneWidget);
    verify(setup.saveStep(SetupStep.welcome)).called(1);
  });

  testWidgets('continues from Your photo to the weather and picks', (
    tester,
  ) async {
    await tester.pumpWidget(app(step: SetupStep.photo));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Continue'));
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('3 / 6'), findsOneWidget);
    verify(setup.saveStep(SetupStep.picks)).called(1);
  });

  testWidgets('starts in English even when the device language is Spanish', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('es');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets(
    'renders a restored Chinese preference on the first localized frame',
    (tester) async {
      await tester.pumpWidget(app(language: SupportedLanguages.chinese));
      await tester.pumpAndSettle();
      expect(find.text('首页'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
    },
  );

  testWidgets(
    'switches all visible copy to Spanish from Settings through the BLoC',
    (tester) async {
      when(
        preferences.setLanguage(SupportedLanguages.spanish),
      ).thenAnswer((_) async => const Right(SupportedLanguages.spanish));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await chooseLanguage(
        tester,
        tab: 'Settings',
        row: 'Language',
        name: 'Español',
      );
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      verify(preferences.setLanguage(SupportedLanguages.spanish)).called(1);
    },
  );

  testWidgets('opens the language sheet over the tab bar', (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(findLink('Change'));
    await tester.pumpAndSettle();
    expect(find.byType(InVogueSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TabShell),
        matching: find.byType(InVogueSheet),
      ),
      findsNothing,
    );
  });

  testWidgets(
    'shows a localized failure and keeps the language after a failed save',
    (tester) async {
      when(
        preferences.setLanguage(any),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      await tester.pumpWidget(app(language: SupportedLanguages.spanish));
      await tester.pumpAndSettle();
      await chooseLanguage(tester, tab: 'Ajustes', row: 'Idioma', name: '中文');
      expect(
        find.text('No pudimos guardar tus cambios. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.text('Idioma'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
    },
  );

  testWidgets('fits a small screen at 200% text in either phone appearance', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.binding.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
    );
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    for (final brightness in Brightness.values) {
      tester.binding.platformDispatcher.platformBrightnessTestValue =
          brightness;
      for (final step in [SetupStep.welcome, SetupStep.done]) {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpWidget(
          app(language: SupportedLanguages.spanish, step: step),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final context = tester.element(find.byType(Scaffold).first);
        expect(Theme.of(context).brightness, Brightness.light);
        expect(
          Theme.of(context).scaffoldBackgroundColor,
          const Color(0xFFFFFFFF),
        );
      }
    }
  });
}
