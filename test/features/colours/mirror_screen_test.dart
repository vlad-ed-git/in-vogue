import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';
import 'package:in_vogue/features/colours/presentation/bloc/colours_bloc.dart';
import 'package:in_vogue/features/colours/presentation/screens/mirror_screen.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:in_vogue/features/wardrobe/presentation/bloc/wardrobe_bloc.dart';
import 'package:mocktail/mocktail.dart' as mocktail;

import '../../helpers/pump_in_vogue.dart';

class _MockColoursBloc extends MockBloc<ColoursEvent, ColoursState>
    implements ColoursBloc {}

class _MockPhotoBloc extends MockBloc<PhotoEvent, PhotoState>
    implements PhotoBloc {}

class _MockWardrobeBloc extends MockBloc<WardrobeEvent, WardrobeState>
    implements WardrobeBloc {}

/// An empty wardrobe, read.
_MockWardrobeBloc _wardrobe() {
  final bloc = _MockWardrobeBloc();
  whenListen(
    bloc,
    const Stream<WardrobeState>.empty(),
    initialState: const WardrobeState(status: WardrobeStatus.ready),
  );
  return bloc;
}

/// Golden blonde hair on peachy fair skin: Light Spring.
const _colours = FaceColours(
  skin: '#F3D3B5',
  eyebrow: '#A07850',
  lip: '#C98276',
  hair: '#C9A26B',
  clear: true,
);

void main() {
  late _MockColoursBloc colours;
  late _MockPhotoBloc photo;

  setUpAll(() {
    mocktail.registerFallbackValue(const ColoursShown());
    mocktail.registerFallbackValue(const PhotoChooseRequested());
  });

  Future<void> pumpMirror(
    WidgetTester tester,
    ColoursState state, {
    PhotoState face = const PhotoState(),
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    colours = _MockColoursBloc();
    photo = _MockPhotoBloc();
    whenListen(
      colours,
      const Stream<ColoursState>.empty(),
      initialState: state,
    );
    whenListen(photo, const Stream<PhotoState>.empty(), initialState: face);
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ColoursBloc>.value(value: colours),
          BlocProvider<PhotoBloc>.value(value: photo),
          BlocProvider<WardrobeBloc>.value(value: _wardrobe()),
        ],
        child: MirrorScreen(onAddOutfit: () {}),
      ),
      scroll: false,
      size: size,
      textScale: textScale,
    );
    await pumpWhileLoading(tester);
  }

  final ready = ColoursState(
    status: ColoursStatus.ready,
    reading: SeasonRules.readingOf(_colours),
  );

  testWidgets('shows the season, why, and the colours in round swatches, '
      'then My wardrobe; never the face photo', (tester) async {
    await pumpMirror(tester, ready);
    expect(find.text('Mirror'), findsOneWidget);
    expect(find.text('YOUR SEASON'), findsOneWidget);
    expect(find.text('Light Spring'), findsOneWidget);
    expect(
      find.text(
        'Fresh, delicate colours suit you: peach, coral and warm aqua.',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Warm undertone · light colouring · medium contrast'),
      findsOneWidget,
    );
    final palette = SeasonRules.readingOf(_colours).palette;
    expect(
      find.byType(Swatch),
      findsNWidgets(
        palette.suits.length + palette.neutrals.length + palette.avoid.length,
      ),
    );
    for (final heading in [
      'Colours that suit you',
      'Your neutrals',
      'Go easy on',
      'My wardrobe',
    ]) {
      await tester.scrollUntilVisible(find.text(heading), 200);
      expect(find.text(heading), findsOneWidget);
    }
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('says when the photo was too unclear to trust', (tester) async {
    await pumpMirror(
      tester,
      ColoursState(
        status: ColoursStatus.ready,
        reading: SeasonRules.readingOf(SeasonRules.neutralColours),
      ),
    );
    expect(
      find.text(
        'The photo wasn’t clear, so this is a starting point. A selfie in '
        'daylight, facing forward, reads better.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('without a face photo, asks for a selfie for the analysis', (
    tester,
  ) async {
    await pumpMirror(tester, const ColoursState(status: ColoursStatus.noPhoto));
    expect(find.text('Find your colours'), findsOneWidget);
    expect(
      find.text('Add a selfie for your skin tone and colour analysis.'),
      findsOneWidget,
    );
    final choose = find.widgetWithText(InVogueButton, 'Choose from Gallery');
    await tester.ensureVisible(choose);
    await tester.tap(choose);
    mocktail.verify(() => photo.add(const PhotoChooseRequested())).called(1);
  });

  testWidgets('runs the rule while it reads the colours', (tester) async {
    await pumpMirror(tester, const ColoursState(status: ColoursStatus.reading));
    expect(find.text('Reading your colours…'), findsOneWidget);
    expect(find.byType(RunningRule), findsOneWidget);
  });

  testWidgets('says what to change in a refused photo, and offers another', (
    tester,
  ) async {
    await pumpMirror(
      tester,
      const ColoursState(
        status: ColoursStatus.failed,
        failure: AnalysisFailure(
          AnalysisProblem.photo,
          advice: PhotoAdvice.lookStraight,
        ),
      ),
    );
    expect(
      find.text(
        'Your face is turned or tilted in this photo. Choose one where you '
        'look straight ahead.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Choose a different photo'));
    mocktail.verify(() => photo.add(const PhotoChooseRequested())).called(1);
  });

  testWidgets('offers Try again after a failure worth trying again', (
    tester,
  ) async {
    await pumpMirror(
      tester,
      const ColoursState(
        status: ColoursStatus.failed,
        failure: NetworkFailure(),
      ),
    );
    await tester.tap(find.text('Try again'));
    mocktail.verify(() => colours.add(const ColoursShown())).called(1);
  });

  testWidgets('reads a face photo kept from here', (tester) async {
    colours = _MockColoursBloc();
    photo = _MockPhotoBloc();
    whenListen(
      colours,
      const Stream<ColoursState>.empty(),
      initialState: const ColoursState(status: ColoursStatus.noPhoto),
    );
    whenListen(
      photo,
      Stream.value(
        const PhotoState(
          status: PhotoStatus.confirmed,
          path: '/photos/face-3.png',
          isKept: true,
        ),
      ),
      initialState: const PhotoState(),
    );
    await pumpInVogue(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ColoursBloc>.value(value: colours),
          BlocProvider<PhotoBloc>.value(value: photo),
          BlocProvider<WardrobeBloc>.value(value: _wardrobe()),
        ],
        child: MirrorScreen(onAddOutfit: () {}),
      ),
      scroll: false,
    );
    await tester.pump();
    mocktail.verify(() => colours.add(const ColoursShown())).called(1);
  });

  testWidgets('fits a 320-point phone at 200% text', (tester) async {
    await pumpMirror(tester, ready, size: const Size(320, 640), textScale: 2);
    expect(tester.takeException(), isNull);
  });
}
