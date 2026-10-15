import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/locate_user.dart';
import 'package:in_vogue/features/location/domain/usecases/open_location_settings.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/welcome_screen.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/pump_in_vogue.dart';
import '../location/location_repository_test.mocks.dart';

const _newYork = UserLocation(latitude: 40.71, longitude: -74.01);

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

void main() {
  late MockLocationRepository repository;
  late int located;

  setUp(() {
    repository = MockLocationRepository();
    when(repository.openSettings(any)).thenAnswer((_) async {});
    located = 0;
  });

  void answerLocate(Either<Failure, UserLocation> result) => when(
    repository.locate(
      askPermission: anyNamed('askPermission'),
      languageCode: anyNamed('languageCode'),
    ),
  ).thenAnswer((_) async => result);

  Future<void> pumpWelcome(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    await pumpInVogue(
      tester,
      BlocProvider(
        create: (_) => LocationBloc(
          locateUser: LocateUser(repository),
          openLocationSettings: OpenLocationSettings(repository),
        ),
        child: WelcomeScreen(onLocated: () => located++),
      ),
      locale: locale,
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('introduces In Vogue and asks for the location', (tester) async {
    await pumpWelcome(tester);
    expect(find.text('In Vogue'), findsOneWidget);
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

  testWidgets('moves on once the location is found, in the screen language', (
    tester,
  ) async {
    answerLocate(const Right(_newYork));
    await pumpWelcome(tester, locale: const Locale('es'));
    await tester.tap(_button('Usar mi ubicación'));
    await tester.pumpAndSettle();
    expect(located, 1);
    verify(
      repository.locate(askPermission: true, languageCode: 'es'),
    ).called(1);
  });

  testWidgets('cannot be tapped again while the location is found', (
    tester,
  ) async {
    final answer = Completer<Either<Failure, UserLocation>>();
    when(
      repository.locate(
        askPermission: anyNamed('askPermission'),
        languageCode: anyNamed('languageCode'),
      ),
    ).thenAnswer((_) => answer.future);
    await pumpWelcome(tester);
    await tester.tap(_button('Use my location'));
    await tester.pump();
    expect(
      tester.widget<InVogueButton>(_button('Use my location')).onPressed,
      isNull,
    );
    answer.complete(const Right(_newYork));
    await tester.pumpAndSettle();
    expect(located, 1);
  });

  testWidgets(
    'replaces the button with the location notice when refused, and opens settings',
    (tester) async {
      answerLocate(const Left(LocationFailure(LocationProblem.deniedForever)));
      await pumpWelcome(tester);
      await tester.tap(_button('Use my location'));
      await tester.pumpAndSettle();
      expect(
        find.text('In Vogue needs your location for the weather.'),
        findsOneWidget,
      );
      expect(_button('Use my location'), findsNothing);
      await tester.tap(_button('Open settings'));
      await tester.pumpAndSettle();
      verify(repository.openSettings(LocationProblem.deniedForever)).called(1);
      expect(located, 0);
    },
  );

  testWidgets('checks again without asking on return from settings', (
    tester,
  ) async {
    answerLocate(const Left(LocationFailure(LocationProblem.denied)));
    await pumpWelcome(tester);
    await tester.tap(_button('Use my location'));
    await tester.pumpAndSettle();
    answerLocate(const Right(_newYork));
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    verify(
      repository.locate(askPermission: false, languageCode: 'en'),
    ).called(1);
    expect(located, 1);
  });

  testWidgets('offers to try again when the position cannot be found', (
    tester,
  ) async {
    answerLocate(const Left(LocationFailure(LocationProblem.unavailable)));
    await pumpWelcome(tester);
    await tester.tap(_button('Use my location'));
    await tester.pumpAndSettle();
    expect(find.text('We couldn’t find where you are.'), findsOneWidget);
    answerLocate(const Right(_newYork));
    await tester.tap(_button('Try again'));
    await tester.pumpAndSettle();
    expect(located, 1);
    verify(
      repository.locate(askPermission: true, languageCode: 'en'),
    ).called(2);
  });

  testWidgets('says when the location could not be saved', (tester) async {
    answerLocate(const Left(CacheFailure()));
    await pumpWelcome(tester);
    await tester.tap(_button('Use my location'));
    await tester.pumpAndSettle();
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
