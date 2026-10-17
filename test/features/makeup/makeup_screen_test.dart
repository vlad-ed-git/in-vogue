import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/presentation/bloc/makeup_bloc.dart';
import 'package:in_vogue/features/makeup/presentation/screens/makeup_screen.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

class _MockMakeupBloc extends MockBloc<MakeupEvent, MakeupState>
    implements MakeupBloc {}

class _MockPhotoBloc extends MockBloc<PhotoEvent, PhotoState>
    implements PhotoBloc {}

Finder _button(String label) =>
    find.ancestor(of: find.text(label), matching: find.byType(InVogueButton));

Future<void> _tapInView(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pump();
}

final _outfit = DayOutfit(
  outfit: const Outfit(
    id: 'o1',
    signature: 'coat+tee',
    pieces: ['everlane:tee', 'everlane:coat'],
    passes: [],
    palette: OutfitPalette.coolNeutral,
  ),
  date: DateTime.utc(2026, 10, 18),
  occasion: Occasion.work,
  cell: 'cool|wet|calm|work',
  picture: '/support/outfits/uid-1/coat+tee.jpg',
);
final _day = MakeupDay(
  day: ForecastDay.tomorrow,
  occasion: Occasion.work,
  outfit: _outfit,
);

const _steps = [
  LookStep(
    title: 'Even base',
    howTo: 'Press a light tint over the centre of the face.',
    products: ['foundation in your shade', 'concealer one shade lighter'],
    picture: '/phone/coat+tee/step-1.jpg',
  ),
  LookStep(
    title: 'Soft taupe eyes',
    howTo: 'Sweep taupe over the lids.',
    products: ['taupe eyeshadow'],
    picture: '/phone/coat+tee/step-2.jpg',
  ),
  LookStep(
    title: 'Rosy-nude lips',
    howTo: 'Fill them in.',
    products: ['rosy-nude lipstick'],
    picture: '/phone/coat+tee/step-3.jpg',
  ),
];

MakeupLook _look({bool matched = true, DateTime? date}) => MakeupLook(
  outfitSignature: 'coat+tee',
  date: date ?? DateTime.utc(2026, 10, 18),
  occasion: Occasion.work,
  palette: OutfitPalette.coolNeutral,
  cheeks: CheekColour.rose,
  lips: LipColour.rosyNude,
  before: '/phone/coat+tee/before.png',
  steps: _steps,
  matched: matched,
);

const _keptFace = PhotoState(
  status: PhotoStatus.chosen,
  path: '/support/photos/face-1.jpg',
  isKept: true,
);

void main() {
  late _MockMakeupBloc makeup;
  late _MockPhotoBloc face;
  late List<(String, String)> opened;

  setUpAll(() {
    registerFallbackValue(const MakeupRequested());
    registerFallbackValue(const PhotoLoaded());
  });

  setUp(() {
    makeup = _MockMakeupBloc();
    face = _MockPhotoBloc();
    opened = [];
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required MakeupState state,
    PhotoState faceState = _keptFace,
    Stream<PhotoState> faceStates = const Stream.empty(),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    whenListen(makeup, const Stream<MakeupState>.empty(), initialState: state);
    whenListen(face, faceStates, initialState: faceState);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<MakeupBloc>.value(value: makeup),
          BlocProvider<PhotoBloc>.value(value: face),
        ],
        child: MakeupScreen(
          onPicture: (picture, label) => opened.add((picture, label)),
        ),
      ),
      platform: TargetPlatform.iOS,
      size: size,
      textScale: textScale,
      scroll: false,
    );
    await tester.pumpAndSettle();
  }

  MakeupState ready({
    MakeupDay? day,
    MakeupLook? look,
    MakeupLook? lastLook,
    List<LookStep>? making,
    Failure? failure,
  }) => MakeupState(
    day: day ?? _day,
    status: MakeupStatus.ready,
    look: look,
    lastLook: lastLook,
    making: making,
    failure: failure,
  );

  testWidgets('shows the look: before and after, why it suits, and the steps', (
    tester,
  ) async {
    await pumpScreen(tester, state: ready(look: _look()));
    expect(find.text('Makeup for tomorrow'), findsOneWidget);
    expect(find.text('WORKDAY'), findsOneWidget);
    expect(find.text('Before'), findsOneWidget);
    expect(find.text('After'), findsOneWidget);
    expect(
      find.text(
        'Rose cheeks and rosy-nude lips, to go with your cool neutrals.',
      ),
      findsOneWidget,
    );
    expect(find.text('Three steps'), findsOneWidget);
    expect(find.text('Even base'), findsOneWidget);
    expect(
      find.text('Foundation in your shade, concealer one shade lighter'),
      findsOneWidget,
    );
    expect(find.byType(MakeupStep), findsNWidgets(3));
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets("opens a step's picture full size", (tester) async {
    await pumpScreen(tester, state: ready(look: _look()));
    await _tapInView(tester, find.bySemanticsLabel('Your face after step 2'));
    expect(opened, [('/phone/coat+tee/step-2.jpg', 'Your face after step 2')]);
  });

  testWidgets('says when the shades are neutral, not matched', (tester) async {
    await pumpScreen(tester, state: ready(look: _look(matched: false)));
    expect(
      find.text(
        'For shades that match you, use a face photo taken in daylight, '
        'facing forward.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('fills in the steps as each is made', (tester) async {
    await pumpScreen(
      tester,
      state: ready(
        making: [
          _steps.first,
          for (final step in _steps.skip(1))
            LookStep(
              title: step.title,
              howTo: step.howTo,
              products: step.products,
            ),
        ],
      ),
    );
    expect(
      find.text('Your steps appear as each one is ready.'),
      findsOneWidget,
    );
    expect(find.text('Preparing'), findsNWidgets(2));
    expect(find.text('Before'), findsNothing);
    expect(find.byType(InVogueButton), findsNothing);
  });

  testWidgets('asks for a face photo', (tester) async {
    await pumpScreen(tester, state: ready(), faceState: const PhotoState());
    expect(find.text('Add a face photo'), findsOneWidget);
    expect(find.text('Your makeup is made on your own face.'), findsOneWidget);
    await _tapInView(tester, _button('Choose from Photos'));
    verify(() => face.add(const PhotoChooseRequested())).called(1);
  });

  testWidgets('keeps a chosen face photo at once', (tester) async {
    await pumpScreen(
      tester,
      state: ready(),
      faceState: const PhotoState(),
      faceStates: Stream.value(
        const PhotoState(status: PhotoStatus.chosen, path: '/tmp/face.jpg'),
      ),
    );
    verify(() => face.add(const PhotoConfirmed())).called(1);
    verifyNever(() => makeup.add(any()));
  });

  testWidgets("says when it changed the face photo's format", (tester) async {
    await pumpScreen(
      tester,
      state: ready(),
      faceState: const PhotoState(
        status: PhotoStatus.chosen,
        path: '/tmp/face-ready.png',
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

  testWidgets('says when a face photo cannot be used', (tester) async {
    await pumpScreen(
      tester,
      state: ready(),
      faceState: const PhotoState(failure: PhotoFailure(PhotoProblem.unusable)),
    );
    expect(
      find.text('We can’t use this photo. Choose another one.'),
      findsOneWidget,
    );
  });

  testWidgets('asks for the look when a face photo added elsewhere shows', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      state: ready(),
      faceState: const PhotoState(),
      faceStates: Stream.value(_keptFace),
    );
    verify(() => makeup.add(const MakeupRequested())).called(1);
  });

  testWidgets('asks nothing again when the same face photo shows again', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      state: ready(),
      faceStates: Stream.value(_keptFace),
    );
    verifyNever(() => makeup.add(any()));
  });

  testWidgets('asks for the look once the face photo is kept', (tester) async {
    await pumpScreen(
      tester,
      state: ready(),
      faceState: const PhotoState(
        status: PhotoStatus.chosen,
        path: '/tmp/face.jpg',
      ),
      faceStates: Stream.value(
        const PhotoState(
          status: PhotoStatus.confirmed,
          path: '/support/photos/face-2.jpg',
          isKept: true,
        ),
      ),
    );
    verify(() => makeup.add(const MakeupRequested())).called(1);
  });

  testWidgets('shows the last look below the face photo, with no button', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      state: ready(lastLook: _look(date: DateTime.utc(2026, 10, 16))),
    );
    expect(find.byType(InVogueButton), findsNothing);
    expect(find.text('Your last look'), findsOneWidget);
    expect(find.text('Work · Fri 16 Oct'), findsOneWidget);
    expect(find.text('Three steps'), findsOneWidget);
  });

  testWidgets('waits for the outfit before any makeup', (tester) async {
    await pumpScreen(
      tester,
      state: ready(
        day: const MakeupDay(day: ForecastDay.tomorrow, outfitPending: true),
      ),
    );
    expect(
      find.text('Your makeup follows your outfit, which is on its way.'),
      findsOneWidget,
    );
    expect(find.byType(InVogueButton), findsNothing);
  });

  testWidgets('has no makeup without an outfit', (tester) async {
    await pumpScreen(
      tester,
      state: ready(day: const MakeupDay(day: ForecastDay.today)),
    );
    expect(find.text('Makeup for today'), findsOneWidget);
    expect(
      find.text('There’s no outfit for today to match yet.'),
      findsOneWidget,
    );
    expect(find.byType(InVogueButton), findsNothing);
  });

  testWidgets('offers another photo when the face cannot be used', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      state: ready(failure: const MakeupFailure(MakeupProblem.photo)),
    );
    expect(
      find.text(
        'We couldn’t find your face in this photo. A close-up, facing '
        'forward in daylight, works best.',
      ),
      findsOneWidget,
    );
    await _tapInView(tester, _button('Choose a different photo'));
    verify(() => face.add(const PhotoChooseRequested())).called(1);
  });

  testWidgets('says plainly when no more looks can be made', (tester) async {
    await pumpScreen(
      tester,
      state: ready(failure: const MakeupFailure(MakeupProblem.noCredit)),
    );
    expect(
      find.text('No more makeup looks can be made for now.'),
      findsOneWidget,
    );
    expect(find.text('Try again'), findsNothing);
  });

  testWidgets('tries again after any other failure', (tester) async {
    await pumpScreen(tester, state: ready(failure: const NetworkFailure()));
    await _tapInView(tester, _button('Try again'));
    verify(() => makeup.add(const MakeupRequested())).called(1);
  });

  testWidgets('fits a small phone at 200% text', (tester) async {
    await pumpScreen(
      tester,
      state: ready(look: _look()),
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
    await pumpScreen(
      tester,
      state: ready(lastLook: _look()),
      faceState: const PhotoState(),
      size: const Size(320, 568),
      textScale: 2,
    );
    expect(tester.takeException(), isNull);
  });
}
