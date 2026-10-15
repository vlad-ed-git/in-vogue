import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/app/router/app_router.dart';
import 'package:in_vogue/app/router/app_routes.dart';
import 'package:in_vogue/app/router/app_screens.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/setup/domain/entities/setup_step.dart';
import 'package:in_vogue/features/setup/domain/usecases/save_setup_step.dart';
import 'package:in_vogue/features/setup/presentation/bloc/setup_bloc.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';
import 'package:mockito/mockito.dart';

import '../features/setup/setup_repository_test.mocks.dart';

/// Screens that only say which route they belong to.
final _screens = AppScreens(
  setup: (step) => Scaffold(body: Text('setup:${step.name}')),
  tab: (tab) => Text('tab:${tab.name}'),
);

void main() {
  late MockSetupRepository repository;
  late SetupBloc setup;
  late AppRouter router;

  setUp(() {
    repository = MockSetupRepository();
    when(repository.saveStep(any)).thenAnswer(
      (invocation) async =>
          Right(invocation.positionalArguments.first as SetupStep),
    );
  });

  Future<void> pumpRouter(WidgetTester tester, SetupStep saved) async {
    setup = SetupBloc(
      saveSetupStep: SaveSetupStep(repository),
      initialStep: saved,
    );
    router = AppRouter(setup: setup, screens: _screens);
    addTearDown(() async {
      router.dispose();
      await setup.close();
    });
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router.config,
        theme: InVogueTheme.paper,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('opens Welcome on a fresh install', (tester) async {
    await pumpRouter(tester, SetupStep.welcome);
    expect(find.text('setup:welcome'), findsOneWidget);
    verifyNever(repository.saveStep(any));
  });

  testWidgets(
    'reopens the saved step with the earlier steps behind it for Back',
    (tester) async {
      await pumpRouter(tester, SetupStep.picks);
      expect(find.text('setup:picks'), findsOneWidget);
      router.config.pop();
      await tester.pumpAndSettle();
      expect(find.text('setup:photo'), findsOneWidget);
      expect(setup.state.step, SetupStep.photo);
      verify(repository.saveStep(SetupStep.photo)).called(1);
      router.config.pop();
      await tester.pumpAndSettle();
      expect(find.text('setup:welcome'), findsOneWidget);
      verify(repository.saveStep(SetupStep.welcome)).called(1);
    },
  );

  testWidgets('saves each step the person moves on to', (tester) async {
    await pumpRouter(tester, SetupStep.welcome);
    router.config.go(AppRoutes.forStep(SetupStep.photo));
    await tester.pumpAndSettle();
    expect(find.text('setup:photo'), findsOneWidget);
    verify(repository.saveStep(SetupStep.photo)).called(1);
    router.config.go(AppRoutes.forStep(SetupStep.picks));
    await tester.pumpAndSettle();
    expect(find.text('setup:picks'), findsOneWidget);
    verify(repository.saveStep(SetupStep.picks)).called(1);
  });

  testWidgets('gives every setup step its own route', (tester) async {
    await pumpRouter(tester, SetupStep.welcome);
    for (final step in SetupStep.values.where((s) => s != SetupStep.done)) {
      router.config.go(AppRoutes.forStep(step));
      await tester.pumpAndSettle();
      expect(find.text('setup:${step.name}'), findsOneWidget);
      expect(AppRoutes.stepAt(AppRoutes.forStep(step)), step);
    }
  });

  testWidgets('keeps an unfinished setup on its step', (tester) async {
    await pumpRouter(tester, SetupStep.signIn);
    router.config.go(AppRoutes.home);
    await tester.pumpAndSettle();
    expect(find.text('setup:signIn'), findsOneWidget);
    expect(find.text('tab:home'), findsNothing);
  });

  testWidgets('opens Home with the tab bar once setup is finished', (
    tester,
  ) async {
    await pumpRouter(tester, SetupStep.done);
    expect(find.text('tab:home'), findsOneWidget);
    expect(find.byType(InVogueTabBar), findsOneWidget);
    router.config.go(AppRoutes.forStep(SetupStep.photo));
    await tester.pumpAndSettle();
    expect(find.text('tab:home'), findsOneWidget);
    expect(find.text('setup:photo'), findsNothing);
  });

  testWidgets('goes to Home when the last setup step finishes setup', (
    tester,
  ) async {
    await pumpRouter(tester, SetupStep.widget);
    setup.add(const SetupStepReached(SetupStep.done));
    await tester.pumpAndSettle();
    expect(find.text('tab:home'), findsOneWidget);
    expect(find.text('setup:widget'), findsNothing);
    verify(repository.saveStep(SetupStep.done)).called(1);
  });

  testWidgets('switches tabs from the tab bar and keeps setup finished', (
    tester,
  ) async {
    await pumpRouter(tester, SetupStep.done);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('tab:settings'), findsOneWidget);
    await tester.tap(find.text('Makeup'));
    await tester.pumpAndSettle();
    expect(find.text('tab:makeup'), findsOneWidget);
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();
    expect(find.text('tab:home'), findsOneWidget);
    expect(setup.state.step, SetupStep.done);
    verifyNever(repository.saveStep(any));
  });
}
