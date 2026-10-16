import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/account/domain/entities/account_plan.dart';
import 'package:in_vogue/features/account/domain/usecases/get_plan.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/entities/sign_in_method.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/auth/presentation/bloc/log_out_bloc.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/preferences/domain/usecases/get_default_day.dart';
import 'package:in_vogue/features/preferences/domain/usecases/set_default_day.dart';
import 'package:in_vogue/features/preferences/presentation/bloc/preferences_bloc.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:in_vogue/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:in_vogue/features/settings/presentation/screens/settings_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart' as mockito;
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';
import 'settings_test.mocks.dart';

const _maya = Account(id: 'uid-1', name: 'Maya', method: SignInMethod.apple);
const _paris = UserLocation(
  latitude: 48.86,
  longitude: 2.35,
  city: 'Paris',
  countryCode: 'FR',
);

class _MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockPhotoBloc extends MockBloc<PhotoEvent, PhotoState>
    implements PhotoBloc {}

class _MockLocationBloc extends MockBloc<LocationEvent, LocationState>
    implements LocationBloc {}

class _MockLogOutBloc extends MockBloc<LogOutEvent, LogOutState>
    implements LogOutBloc {}

class _MockPreferencesBloc extends MockBloc<PreferencesEvent, PreferencesState>
    implements PreferencesBloc {}

@GenerateMocks([
  GetCurrentAccount,
  GetPlan,
  GetSavedLocation,
  GetDefaultDay,
  SetDefaultDay,
  SaveSetupToAccount,
])
void main() {
  group('SettingsBloc', () {
    late MockGetCurrentAccount account;
    late MockGetPlan plan;
    late MockGetSavedLocation location;
    late MockGetDefaultDay getDay;
    late MockSetDefaultDay setDay;
    late MockSaveSetupToAccount saveSetup;

    SettingsBloc buildBloc() => SettingsBloc(
      getCurrentAccount: account,
      getPlan: plan,
      getSavedLocation: location,
      getDefaultDay: getDay,
      setDefaultDay: setDay,
      saveSetupToAccount: saveSetup,
    );

    setUp(() {
      account = MockGetCurrentAccount();
      plan = MockGetPlan();
      location = MockGetSavedLocation();
      getDay = MockGetDefaultDay();
      setDay = MockSetDefaultDay();
      saveSetup = MockSaveSetupToAccount();
      mockito
          .when(account(mockito.any))
          .thenAnswer((_) async => const Right(_maya));
      mockito
          .when(plan(mockito.any))
          .thenAnswer((_) async => const Right(AccountPlan.pro));
      mockito
          .when(location(mockito.any))
          .thenAnswer((_) async => const Right(_paris));
      mockito
          .when(getDay(mockito.any))
          .thenAnswer((_) async => const Right(ForecastDay.tomorrow));
      mockito
          .when(setDay(mockito.any))
          .thenAnswer(
            (invocation) async =>
                Right(invocation.positionalArguments.first as ForecastDay),
          );
      mockito
          .when(saveSetup(mockito.any))
          .thenAnswer((_) async => const Right(unit));
    });

    blocTest<SettingsBloc, SettingsState>(
      'reads the account, the place, the default day and the plan',
      build: buildBloc,
      act: (bloc) => bloc.add(const SettingsLoaded()),
      expect: () => [
        const SettingsState(account: _maya, place: _paris),
        const SettingsState(
          account: _maya,
          place: _paris,
          plan: AccountPlan.pro,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'keeps the day Home opens on',
      build: buildBloc,
      act: (bloc) =>
          bloc.add(const SettingsDefaultDayChanged(ForecastDay.today)),
      expect: () => [const SettingsState(defaultDay: ForecastDay.today)],
      verify: (_) => mockito.verify(setDay(ForecastDay.today)).called(1),
    );

    blocTest<SettingsBloc, SettingsState>(
      'saves a change on the account',
      build: buildBloc,
      seed: () => const SettingsState(account: _maya),
      act: (bloc) => bloc.add(const SettingsSetupChanged()),
      expect: () => [const SettingsState(account: _maya, place: _paris)],
      verify: (_) => mockito.verify(saveSetup('uid-1')).called(1),
    );

    blocTest<SettingsBloc, SettingsState>(
      'says when the account cannot be saved',
      build: () {
        mockito
            .when(saveSetup(mockito.any))
            .thenAnswer((_) async => const Left(NetworkFailure()));
        return buildBloc();
      },
      seed: () => const SettingsState(account: _maya, place: _paris),
      act: (bloc) => bloc.add(const SettingsSetupChanged()),
      expect: () => [
        const SettingsState(
          account: _maya,
          place: _paris,
          failure: NetworkFailure(),
        ),
      ],
    );
  });

  group('SettingsScreen', () {
    late _MockSettingsBloc settings;
    late _MockProfileBloc profile;
    late _MockPhotoBloc face;
    late _MockPhotoBloc body;
    late _MockLocationBloc location;

    setUpAll(() {
      registerFallbackValue(const SettingsLoaded());
      registerFallbackValue(const ProfileLoaded());
      registerFallbackValue(const PhotoLoaded());
      registerFallbackValue(const LocationSettingsRequested());
    });

    Future<void> pumpSettings(WidgetTester tester) async {
      settings = _MockSettingsBloc();
      profile = _MockProfileBloc();
      face = _MockPhotoBloc();
      body = _MockPhotoBloc();
      location = _MockLocationBloc();
      final logOut = _MockLogOutBloc();
      final preferences = _MockPreferencesBloc();
      whenListen(
        settings,
        const Stream<SettingsState>.empty(),
        initialState: const SettingsState(
          account: _maya,
          plan: AccountPlan.pro,
          place: _paris,
        ),
      );
      whenListen(
        profile,
        const Stream<ProfileState>.empty(),
        initialState: const ProfileState(
          status: ProfileStatus.ready,
          name: 'Maya',
        ),
      );
      whenListen(
        face,
        const Stream<PhotoState>.empty(),
        initialState: const PhotoState(),
      );
      whenListen(
        body,
        const Stream<PhotoState>.empty(),
        initialState: const PhotoState(
          status: PhotoStatus.chosen,
          path: '/photos/body-3.jpg',
          isKept: true,
        ),
      );
      whenListen(
        location,
        const Stream<LocationState>.empty(),
        initialState: const LocationState(),
      );
      whenListen(
        logOut,
        const Stream<LogOutState>.empty(),
        initialState: const LogOutState(),
      );
      whenListen(
        preferences,
        const Stream<PreferencesState>.empty(),
        initialState: const PreferencesState(
          language: SupportedLanguages.english,
        ),
      );
      await pumpInVogue(
        tester,
        MultiBlocProvider(
          providers: [
            BlocProvider<SettingsBloc>.value(value: settings),
            BlocProvider<ProfileBloc>.value(value: profile),
            BlocProvider<PhotoBloc>.value(value: face),
            BlocProvider<LocationBloc>.value(value: location),
            BlocProvider<LogOutBloc>.value(value: logOut),
            BlocProvider<PreferencesBloc>.value(value: preferences),
          ],
          child: SettingsScreen(onLoggedOut: () {}, bodyPhoto: () => body),
        ),
        scroll: false,
      );
      await tester.pump();
    }

    testWidgets('lists what can change, in the spec’s order', (tester) async {
      await pumpSettings(tester);
      final titles = tester
          .widgetList<SettingsRow>(find.byType(SettingsRow))
          .map((row) => row.title)
          .toList();
      expect(titles, [
        'Maya',
        'Body photo',
        'Face photo',
        'Membership',
        'Location',
        'Default day',
        'Language',
        'Log out',
      ]);
      expect(find.text('Signed in with Apple'), findsOneWidget);
      expect(find.text('Used to dress you'), findsOneWidget);
      expect(find.text('Not added yet'), findsOneWidget);
      expect(find.text('Pro'), findsOneWidget);
      expect(find.text('Paris, while using the app'), findsOneWidget);
      expect(find.text('Tomorrow, today from 6 to 9 am'), findsOneWidget);
      expect(find.textContaining('Theme'), findsNothing);
    });

    testWidgets('Edit changes the name', (tester) async {
      await pumpSettings(tester);
      await tester.tap(findLink('Edit'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.enterText(find.byType(EditableText), 'May');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(() => profile.add(const ProfileNameSaved('May'))).called(1);
    });

    testWidgets('Replace and Add choose a photo', (tester) async {
      await pumpSettings(tester);
      await tester.tap(findLink('Replace'));
      verify(() => body.add(const PhotoChooseRequested())).called(1);
      await tester.tap(findLink('Add'));
      verify(() => face.add(const PhotoChooseRequested())).called(1);
    });

    testWidgets('Change on Location reads the location again', (tester) async {
      await pumpSettings(tester);
      await tester.tap(findLink('Change').first);
      verify(() => location.add(const LocationRequested('en'))).called(1);
    });

    testWidgets('Default day opens a choice of the two days', (tester) async {
      await pumpSettings(tester);
      await tester.ensureVisible(find.text('Tomorrow, today from 6 to 9 am'));
      await tester.tap(findLink('Change').at(1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Home opens on'), findsOneWidget);
      await tester.tap(find.text('Today').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(
        () => settings.add(const SettingsDefaultDayChanged(ForecastDay.today)),
      ).called(1);
    });
  });
}
