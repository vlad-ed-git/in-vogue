import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

final _other = MemoryImage(Uint8List.fromList(testImage.bytes));

void main() {
  group('OccasionLine', () {
    testWidgets('shows the occasion as a 32-point kicker line', (tester) async {
      await pumpInVogue(
        tester,
        const Column(
          children: [
            OccasionLine(occasion: Occasion.work),
            OccasionLine(occasion: Occasion.goingOut),
          ],
        ),
      );
      expect(find.text('WORKDAY'), findsOneWidget);
      expect(find.text('GOING OUT'), findsOneWidget);
      expect(tester.getSize(find.byType(OccasionLine).first).height, 32);
    });

    testWidgets('the sheet lists every occasion and returns the choice', (
      tester,
    ) async {
      Occasion? chosen;
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => chosen = await showOccasionSheet(
              context: context,
              current: Occasion.work,
              day: ForecastDay.tomorrow,
              date: 'Thursday 16 October',
            ),
            child: const Text('Open'),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Tomorrow is'), findsOneWidget);
      expect(find.text('Thursday 16 October'), findsOneWidget);
      for (final label in ['Work', 'Casual', 'Going out', 'Staying in']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(findIcon(InVogueIcons.check), findsOneWidget);
      await tester.tap(find.text('Staying in'));
      await tester.pumpAndSettle();
      expect(chosen, Occasion.stayingIn);
    });

    testWidgets('speaks Spanish and drops capitals in Chinese', (tester) async {
      await pumpInVogue(
        tester,
        const OccasionLine(occasion: Occasion.work),
        locale: const Locale('zh'),
      );
      expect(find.text('工作日'), findsOneWidget);
      await pumpInVogue(
        tester,
        const OccasionLine(occasion: Occasion.work),
        locale: const Locale('es'),
      );
      expect(find.text('DÍA LABORABLE'), findsOneWidget);
    });
  });

  group('PhotoStage', () {
    Widget stage(PhotoStageState state, {ImageProvider? outfit}) => PhotoStage(
      state: state,
      height: 380,
      outfit: outfit ?? testImage,
      photo: testImage,
      outfitLabel: 'You in a mac coat.',
    );

    Widget switchable(PhotoStageState Function() state, VoidCallback onTap) =>
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(onTap),
            child: stage(state()),
          ),
        );

    Iterable<double> opacities(WidgetTester tester) => tester
        .widgetList<Opacity>(
          find.descendant(
            of: find.byType(PhotoStage),
            matching: find.byType(Opacity),
          ),
        )
        .map((o) => o.opacity);

    final curtain = find.byWidgetPredicate(
      (w) => w is ClipRect && w.clipper != null,
    );

    testWidgets('ready: the outfit contained at the stage height', (
      tester,
    ) async {
      await pumpInVogue(tester, stage(PhotoStageState.ready));
      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.contain);
      expect(image.semanticLabel, 'You in a mac coat.');
      expect(tester.getSize(find.byType(PhotoStage)), const Size(350, 380));
      expect(opacities(tester), isEmpty);
    });

    testWidgets('waiting: the own photo at 28% under the message', (
      tester,
    ) async {
      await pumpInVogue(tester, stage(PhotoStageState.waiting));
      expect(opacities(tester), [0.28]);
      expect(find.text('Getting your outfit ready…'), findsOneWidget);
      expect(
        fillOf(
          tester,
          find
              .ancestor(
                of: find.text('Getting your outfit ready…'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        ),
        InVogueColors.accent,
      );
    });

    testWidgets('waiting: a progress line under the message', (tester) async {
      await pumpInVogue(
        tester,
        const PhotoStage(
          state: PhotoStageState.waiting,
          height: 380,
          progress: 'Piece 2 of 3',
        ),
      );
      expect(find.text('Getting your outfit ready…'), findsOneWidget);
      expect(find.text('Piece 2 of 3'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Piece 2 of 3')).dy,
        greaterThan(
          tester.getTopLeft(find.text('Getting your outfit ready…')).dy,
        ),
      );
    });

    testWidgets('idle: the faded photo with nothing over or under it', (
      tester,
    ) async {
      await pumpInVogue(tester, stage(PhotoStageState.idle));
      expect(opacities(tester), [0.28]);
      expect(find.text('Getting your outfit ready…'), findsNothing);
      expect(find.byType(Notice), findsNothing);
      expect(tester.getSize(find.byType(PhotoStage)), const Size(350, 380));
    });

    testWidgets('a finished outfit is revealed top to bottom in 720 ms', (
      tester,
    ) async {
      var state = PhotoStageState.waiting;
      await pumpInVogue(
        tester,
        switchable(() => state, () => state = PhotoStageState.ready),
      );
      await tester.tap(find.byType(PhotoStage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 360));
      final clip = tester
          .widget<ClipRect>(curtain)
          .clipper!
          .getClip(const Size(350, 380));
      expect(clip.top, 0);
      expect(
        clip.height,
        closeTo(380 * InVogueMotion.curtain.transform(0.5), 0.5),
      );
      expect(opacities(tester), [0.28], reason: 'over the faded photo');
      // Completion is reported on the first tick after 720 ms.
      await tester.pump(const Duration(milliseconds: 361));
      await tester.pump();
      expect(curtain, findsNothing);
      expect(opacities(tester), isEmpty);
    });

    testWidgets('with reduced motion the outfit crossfades in 240 ms', (
      tester,
    ) async {
      var state = PhotoStageState.waiting;
      await pumpInVogue(
        tester,
        switchable(() => state, () => state = PhotoStageState.ready),
        disableAnimations: true,
      );
      await tester.tap(find.byType(PhotoStage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(curtain, findsNothing);
      expect(opacities(tester).where((o) => o > 0.28 && o < 1), isNotEmpty);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('a new outfit crossfades with a 4-point settle', (
      tester,
    ) async {
      ImageProvider outfit = testImage;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => outfit = _other),
            child: stage(PhotoStageState.ready, outfit: outfit),
          ),
        ),
      );
      await tester.tap(find.byType(PhotoStage));
      await tester.pump();
      expect(find.byType(Image), findsNWidgets(2));
      final settle = tester.widget<Transform>(
        find
            .ancestor(
              of: find.byType(Image).last,
              matching: find.byType(Transform),
            )
            .first,
      );
      expect(settle.transform.getTranslation().y, 4);
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
    });

    test('heightFor keeps the stage between 300 and width × 5 / 4', () {
      expect(PhotoStage.heightFor(available: 500, width: 350), 437.5);
      expect(PhotoStage.heightFor(available: 404, width: 350), 404);
      expect(PhotoStage.heightFor(available: 200, width: 350), 300);
      // Narrow columns cap the minimum at width × 5 / 4.
      expect(PhotoStage.heightFor(available: 100, width: 200), 250);
    });
  });
}
