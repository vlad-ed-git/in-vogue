import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/app/in_vogue_app.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_language.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:mockito/mockito.dart';

import 'features/preferences/preferences_repository_test.mocks.dart';

void main() {
  late MockPreferencesRepository repository;
  setUp(() {
    repository = MockPreferencesRepository();
  });

  InVogueApp app({SupportedLanguages language = SupportedLanguages.english}) =>
      InVogueApp(
        createPreferencesBloc: () => PreferencesBloc(
          setLanguage: SetLanguage(repository),
          initialLanguage: language,
        ),
      );

  testWidgets('starts in English even when the device language is Spanish', (
    tester,
  ) async {
    tester.binding.platformDispatcher.localeTestValue = const Locale('es');
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();
    expect(find.text('In Vogue'), findsOneWidget);
    expect(find.text('Meet tomorrow’s weather in style.'), findsOneWidget);
  });

  testWidgets(
    'renders a restored Chinese preference on the first localized frame',
    (tester) async {
      await tester.pumpWidget(app(language: SupportedLanguages.chinese));
      await tester.pumpAndSettle();
      expect(find.text('以时尚穿搭，迎接明天的天气。'), findsOneWidget);
      expect(find.text('Meet tomorrow’s weather in style.'), findsNothing);
    },
  );

  testWidgets(
    'switches all visible copy to Spanish through the BLoC and repository',
    (tester) async {
      when(
        repository.setLanguage(SupportedLanguages.spanish),
      ).thenAnswer((_) async => const Right(SupportedLanguages.spanish));
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<SupportedLanguages>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Español').last);
      await tester.pumpAndSettle();
      expect(
        find.text('Viste con estilo para el tiempo de mañana.'),
        findsOneWidget,
      );
      expect(find.text('Idioma'), findsOneWidget);
      verify(repository.setLanguage(SupportedLanguages.spanish)).called(1);
    },
  );

  testWidgets(
    'shows a localized failure and restores the selected language after a failed save',
    (tester) async {
      when(
        repository.setLanguage(any),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      await tester.pumpWidget(app(language: SupportedLanguages.spanish));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<SupportedLanguages>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('中文').last);
      await tester.pumpAndSettle();
      expect(
        find.text('No pudimos guardar tus cambios. Inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(
        find.text('Viste con estilo para el tiempo de mañana.'),
        findsOneWidget,
      );
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
      await tester.pumpWidget(app(language: SupportedLanguages.spanish));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('In Vogue'), findsOneWidget);
      final context = tester.element(find.text('In Vogue'));
      expect(Theme.of(context).brightness, Brightness.light);
      expect(
        Theme.of(context).scaffoldBackgroundColor,
        const Color(0xFFFFFFFF),
      );
    }
  });
}
