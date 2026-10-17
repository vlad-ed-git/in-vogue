import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/setup/presentation/screens/your_photo_screen.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockPhotoBloc extends MockBloc<PhotoEvent, PhotoState>
    implements PhotoBloc {}

const _passed = PhotoState(status: PhotoStatus.chosen, path: '/tmp/me.jpg');

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

void main() {
  late _MockPhotoBloc bloc;
  late int backs;
  late int dones;

  setUp(() {
    bloc = _MockPhotoBloc();
    backs = 0;
    dones = 0;
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    PhotoState state = const PhotoState(),
    Stream<PhotoState> states = const Stream.empty(),
    TargetPlatform platform = TargetPlatform.iOS,
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(bloc, states, initialState: state);
    await pumpInVogue(
      tester,
      BlocProvider<PhotoBloc>.value(
        value: bloc,
        child: YourPhotoScreen(onBack: () => backs++, onDone: () => dones++),
      ),
      platform: platform,
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('asks for a photo with an example, at step 2 of 6', (
    tester,
  ) async {
    await pumpScreen(tester);
    expect(find.text('2 / 6'), findsOneWidget);
    expect(find.text('Add a photo of you'), findsOneWidget);
    expect(find.text('We dress this photo in each outfit.'), findsOneWidget);
    expect(find.text('Head to toe'), findsOneWidget);
    expect(
      find.text(
        'Your photo is only used to dress you in outfits. '
        'You can replace it any time.',
      ),
      findsOneWidget,
    );
    await tester.tap(_button('Choose from Photos'));
    verify(() => bloc.add(const PhotoChooseRequested())).called(1);
  });

  testWidgets('says Gallery on Android', (tester) async {
    await pumpScreen(tester, platform: TargetPlatform.android);
    expect(_button('Choose from Gallery'), findsOneWidget);
    expect(find.text('Choose from Photos'), findsNothing);
  });

  testWidgets('trusts the chosen photo: Continue, or choose another', (
    tester,
  ) async {
    await pumpScreen(tester, state: _passed);
    await tester.tap(_button('Continue'));
    verify(() => bloc.add(const PhotoConfirmed())).called(1);
    await tester.tap(findLink('Choose a different photo'));
    verify(() => bloc.add(const PhotoChooseRequested())).called(1);
  });

  testWidgets('cannot continue while the photo is being kept', (tester) async {
    await pumpScreen(
      tester,
      state: const PhotoState(
        status: PhotoStatus.chosen,
        path: '/tmp/me.jpg',
        busy: true,
      ),
    );
    expect(tester.widget<InVogueButton>(_button('Continue')).onPressed, isNull);
  });

  testWidgets('says when a photo cannot be opened', (tester) async {
    await pumpScreen(
      tester,
      state: const PhotoState(failure: PhotoFailure(PhotoProblem.unreadable)),
    );
    expect(
      find.text('We couldn’t open this photo. Choose another one.'),
      findsOneWidget,
    );
  });

  testWidgets('moves on once the photo is kept', (tester) async {
    await pumpScreen(
      tester,
      state: _passed,
      states: Stream.value(
        const PhotoState(
          status: PhotoStatus.confirmed,
          path: '/app/body-1.jpg',
          isKept: true,
        ),
      ),
    );
    expect(dones, 1);
  });

  testWidgets('goes back', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.text('Back'));
    expect(backs, 1);
  });

  testWidgets('scrolls on a small phone at 200% text', (tester) async {
    await pumpScreen(
      tester,
      state: _passed,
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(_button('Continue'), 100);
    expect(_button('Continue'), findsOneWidget);
  });
}
