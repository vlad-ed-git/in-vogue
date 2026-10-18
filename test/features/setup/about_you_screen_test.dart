import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/about_you_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockProfileBloc extends MockBloc<ProfileEvent, ProfileState>
    implements ProfileBloc {}

class _MockPhotoBloc extends MockBloc<PhotoEvent, PhotoState>
    implements PhotoBloc {}

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

Future<void> _tapInView(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

void main() {
  late _MockProfileBloc profile;
  late _MockPhotoBloc face;
  late int backs;
  late int dones;

  setUp(() {
    profile = _MockProfileBloc();
    face = _MockPhotoBloc();
    backs = 0;
    dones = 0;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    ProfileState state = const ProfileState(
      status: ProfileStatus.ready,
      name: 'Maya',
    ),
    Stream<ProfileState> states = const Stream.empty(),
    PhotoState faceState = const PhotoState(),
    Stream<PhotoState> faceStates = const Stream.empty(),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(profile, states, initialState: state);
    whenListen(face, faceStates, initialState: faceState);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ProfileBloc>.value(value: profile),
          BlocProvider<PhotoBloc>.value(value: face),
        ],
        child: AboutYouScreen(onBack: () => backs++, onDone: () => dones++),
      ),
      platform: TargetPlatform.iOS,
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks for a name and an optional face photo at step 5 of 6', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('5 / 6'), findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Add a selfie'), findsOneWidget);
    expect(
      find.text('Optional. It’s for your skin tone and colour analysis.'),
      findsOneWidget,
    );
    expect(find.text('Close up'), findsOneWidget);
    final choose = tester.widget<InVogueButton>(_button('Choose from Photos'));
    expect(choose.kind, InVogueButtonKind.secondary);
  });

  testWidgets('saves the name as typed and moves on', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byType(EditableText), 'May');
    await _tapInView(tester, _button('Continue'));
    verify(() => profile.add(const ProfileNameSaved('May'))).called(1);
  });

  testWidgets('needs a name to continue', (tester) async {
    await pumpScreen(
      tester,
      state: const ProfileState(status: ProfileStatus.ready),
    );
    expect(tester.widget<InVogueButton>(_button('Continue')).onPressed, isNull);
    await tester.enterText(find.byType(EditableText), 'Maya');
    await tester.pump();
    expect(
      tester.widget<InVogueButton>(_button('Continue')).onPressed,
      isNotNull,
    );
  });

  testWidgets('fills in the name once it is loaded', (tester) async {
    await pumpScreen(
      tester,
      state: const ProfileState(),
      states: Stream.value(
        const ProfileState(status: ProfileStatus.ready, name: 'Maya'),
      ),
    );
    expect(find.text('Maya'), findsOneWidget);
  });

  testWidgets('opens the system picker for a face photo', (tester) async {
    await pumpScreen(tester);
    await _tapInView(tester, _button('Choose from Photos'));
    verify(() => face.add(const PhotoChooseRequested())).called(1);
  });

  testWidgets('keeps a chosen face photo at once', (tester) async {
    await pumpScreen(
      tester,
      faceStates: Stream.value(
        const PhotoState(status: PhotoStatus.chosen, path: '/tmp/face.jpg'),
      ),
    );
    verify(() => face.add(const PhotoConfirmed())).called(1);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets("says when it changed the face photo's format", (tester) async {
    await pumpScreen(
      tester,
      faceState: const PhotoState(
        status: PhotoStatus.confirmed,
        path: '/support/photos/face-2.png',
        isKept: true,
        converted: true,
      ),
    );
    expect(
      find.text(
        'We changed this photo’s format so it works. Don’t like it? Choose another.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('says when a face photo is too small', (tester) async {
    await pumpScreen(
      tester,
      faceState: const PhotoState(failure: PhotoFailure(PhotoProblem.tooSmall)),
    );
    expect(
      find.text('This photo is too small. Choose a larger one.'),
      findsOneWidget,
    );
  });

  testWidgets('moves on once the name is saved', (tester) async {
    await pumpScreen(
      tester,
      states: Stream.value(
        const ProfileState(status: ProfileStatus.saved, name: 'Maya'),
      ),
    );
    expect(dones, 1);
  });

  testWidgets('says when the name cannot be saved', (tester) async {
    await pumpScreen(
      tester,
      state: const ProfileState(
        status: ProfileStatus.ready,
        name: 'Maya',
        failure: CacheFailure(),
      ),
    );
    expect(
      find.text('We couldn’t save your changes. Please try again.'),
      findsOneWidget,
    );
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
