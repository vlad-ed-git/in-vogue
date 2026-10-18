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
import 'package:in_vogue/features/account/presentation/bloc/delete_account_bloc.dart';
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

class _MockDeleteAccountBloc
    extends MockBloc<DeleteAccountEvent, DeleteAccountState>
    implements DeleteAccountBloc {}

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
    late _MockDeleteAccountBloc deletion;
    late bool placed;
    late int widgetAsks;

    setUpAll(() {
      registerFallbackValue(const SettingsLoaded());
      registerFallbackValue(const ProfileLoaded());
      registerFallbackValue(const PhotoLoaded());
      registerFallbackValue(const LocationSettingsRequested());
      registerFallbackValue(const DeleteAccountConfirmed());
    });

    Future<void> pumpSettings(
      WidgetTester tester, {
      Stream<PhotoState> bodyStates = const Stream.empty(),
      bool launcherPlaces = true,
      TargetPlatform? platform,
    }) async {
      placed = false;
      widgetAsks = 0;
      settings = _MockSettingsBloc();
      profile = _MockProfileBloc();
      face = _MockPhotoBloc();
      body = _MockPhotoBloc();
      location = _MockLocationBloc();
      deletion = _MockDeleteAccountBloc();
      whenListen(
        deletion,
        const Stream<DeleteAccountState>.empty(),
        initialState: const DeleteAccountState(),
      );
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
        bodyStates,
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
            BlocProvider<DeleteAccountBloc>.value(value: deletion),
          ],
          child: SettingsScreen(
            onLoggedOut: () {},
            onAccountDeleted: () {},
            bodyPhoto: () => body,
            onAddWidget: () async {
              widgetAsks++;
              placed = launcherPlaces;
              return launcherPlaces;
            },
          ),
        ),
        scroll: false,
        platform: platform,
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
        'Home-screen widget',
        'Log out',
        'Delete account',
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
      await tester.tap(findLink('Add').first);
      verify(() => face.add(const PhotoChooseRequested())).called(1);
    });

    Future<void> addWidget(WidgetTester tester) async {
      final row = find.ancestor(
        of: find.text('Home-screen widget'),
        matching: find.byType(SettingsRow),
      );
      await tester.ensureVisible(row);
      await tester.pump();
      await tester.tap(find.descendant(of: row, matching: findLink('Add')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets("Add on the widget row has Android's launcher place it", (
      tester,
    ) async {
      await pumpSettings(tester);
      await addWidget(tester);
      expect(widgetAsks, 1);
      expect(placed, isTrue);
      expect(find.text('Add In Vogue to your home screen'), findsNothing);
    });

    testWidgets("says how to add it by hand when the launcher can't place "
        'it', (tester) async {
      await pumpSettings(tester, launcherPlaces: false);
      await addWidget(tester);
      expect(widgetAsks, 1);
      expect(find.text('Add In Vogue to your home screen'), findsOneWidget);
      expect(
        find.text(
          'Add it from your home screen: press and hold, tap Widgets, '
          'choose In Vogue.',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Done'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Add In Vogue to your home screen'), findsNothing);
    });

    testWidgets('shows the three steps on iPhone', (tester) async {
      await pumpSettings(tester, platform: TargetPlatform.iOS);
      await addWidget(tester);
      expect(widgetAsks, 0);
      expect(find.text('Add In Vogue to your home screen'), findsOneWidget);
      expect(find.text('Press and hold your home screen'), findsOneWidget);
      expect(find.text('Tap +'), findsOneWidget);
      expect(find.text('Choose In Vogue'), findsOneWidget);
    });

    testWidgets("says when it changed a new photo's format, once kept", (
      tester,
    ) async {
      await pumpSettings(
        tester,
        bodyStates: Stream.value(
          const PhotoState(
            status: PhotoStatus.confirmed,
            path: '/photos/body-4.png',
            isKept: true,
            converted: true,
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text(
          'We changed this photo’s format so it works. Don’t like it? Choose another.',
        ),
        findsOneWidget,
      );
      verify(() => settings.add(const SettingsSetupChanged())).called(1);
    });

    testWidgets('says why a new photo cannot be used', (tester) async {
      await pumpSettings(
        tester,
        bodyStates: Stream.value(
          const PhotoState(
            status: PhotoStatus.chosen,
            path: '/photos/body-3.jpg',
            isKept: true,
            failure: PhotoFailure(PhotoProblem.tooSmall),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.text('This photo is too small. Choose a larger one.'),
        findsOneWidget,
      );
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

    testWidgets('Delete account asks once more, and Keep keeps it', (
      tester,
    ) async {
      await pumpSettings(tester);
      await tester.ensureVisible(find.text('Delete account'));
      await tester.pump();
      await tester.tap(find.text('Delete account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Delete your account?'), findsOneWidget);
      await tester.tap(find.text('Keep my account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verifyNever(() => deletion.add(any()));
    });

    testWidgets('Delete account deletes once confirmed', (tester) async {
      await pumpSettings(tester);
      await tester.ensureVisible(find.text('Delete account'));
      await tester.pump();
      await tester.tap(find.text('Delete account'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.text('Delete account').last);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(() => deletion.add(const DeleteAccountConfirmed())).called(1);
    });
  });
}
