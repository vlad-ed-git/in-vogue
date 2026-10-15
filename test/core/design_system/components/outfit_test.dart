import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/design_system/design_system.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';

import '../../../helpers/pump_in_vogue.dart';

final _other = MemoryImage(Uint8List.fromList(testImage.bytes));

void main() {
  group('OccasionLine', () {
    testWidgets('shows the kicker and Change only when it can change', (
      tester,
    ) async {
      var changes = 0;
      await pumpInVogue(
        tester,
        Column(
          children: [
            OccasionLine(occasion: Occasion.work, onChange: () => changes++),
            const OccasionLine(occasion: Occasion.goingOut),
          ],
        ),
      );
      expect(find.text('WORKDAY'), findsOneWidget);
      expect(find.text('GOING OUT'), findsOneWidget);
      expect(findLink('Change'), findsOneWidget);
      expect(tester.getSize(find.byType(OccasionLine).first).height, 32);
      await tester.tap(findLink('Change'));
      expect(changes, 1);
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
      onRetry: () {},
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

    testWidgets('failed: the faded photo and a retry notice 12 below', (
      tester,
    ) async {
      await pumpInVogue(tester, stage(PhotoStageState.failed));
      expect(opacities(tester), [0.28]);
      final stageTop = tester.getTopLeft(find.byType(PhotoStage)).dy;
      expect(tester.getTopLeft(find.byType(Notice)).dy - stageTop, 380 + 12);
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

  group('OutfitTiles', () {
    final outfits = [testImage, _other, testImage];

    testWidgets('three 4:5 tiles; the shown one outlined and checked', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      int? chosen;
      await pumpInVogue(
        tester,
        OutfitTiles(
          outfits: outfits,
          selectedIndex: 0,
          onSelected: (i) => chosen = i,
        ),
      );
      final tiles = tester.widgetList<PhotoSlot>(find.byType(PhotoSlot));
      expect(tiles, hasLength(3));
      final first = tester.getRect(find.byType(PhotoSlot).first);
      final second = tester.getRect(find.byType(PhotoSlot).at(1));
      expect(first.width, closeTo((350 - 24) / 3, 1e-9));
      expect(first.height, closeTo(first.width * 5 / 4, 1e-9));
      expect(second.left - first.right, 12);
      expect(find.byType(CheckBadge), findsOneWidget);
      expect(find.bySemanticsLabel('Outfit 1 of 3, shown'), findsOneWidget);
      expect(find.bySemanticsLabel('Outfit 2 of 3'), findsOneWidget);
      await tester.tap(find.byType(PhotoSlot).at(2));
      expect(chosen, 2);
      handle.dispose();
    });

    testWidgets('two per row at large text', (tester) async {
      await pumpInVogue(
        tester,
        OutfitTiles(outfits: outfits, selectedIndex: 0, onSelected: (_) {}),
        textScale: 2,
      );
      final first = tester.getRect(find.byType(PhotoSlot).first);
      final third = tester.getRect(find.byType(PhotoSlot).at(2));
      expect(first.width, closeTo((350 - 12) / 2, 1e-9));
      expect(third.top, greaterThan(first.bottom));
    });

    testWidgets('fewer outfits sit flush left with their note', (tester) async {
      await pumpInVogue(
        tester,
        OutfitTiles(
          outfits: [testImage],
          selectedIndex: 0,
          onSelected: (_) {},
          note: 'Only one other outfit suits tomorrow.',
        ),
      );
      expect(find.byType(PhotoSlot), findsOneWidget);
      expect(tester.getTopLeft(find.byType(PhotoSlot)).dx, 20);
      expect(
        find.text('Only one other outfit suits tomorrow.'),
        findsOneWidget,
      );
    });

    testWidgets('preparing: three Rose slots and a waiting line', (
      tester,
    ) async {
      await pumpInVogue(tester, const OutfitTiles.preparing());
      final slots = tester.widgetList<PhotoSlot>(find.byType(PhotoSlot));
      expect(slots.every((s) => s.image == null), isTrue);
      expect(find.text('Other outfits are on their way.'), findsOneWidget);
    });

    testWidgets('locked: faded with a lock and a Go Pro link', (tester) async {
      var goPro = 0;
      await pumpInVogue(
        tester,
        OutfitTiles.locked(outfits: outfits, onGoPro: () => goPro++),
      );
      final slots = tester.widgetList<PhotoSlot>(find.byType(PhotoSlot));
      expect(slots.every((s) => s.opacity == 0.45), isTrue);
      expect(findIcon(InVogueIcons.lock), findsNWidgets(3));
      expect(
        find.textContaining('Other outfits come with Pro.', findRichText: true),
        findsOneWidget,
      );
      await tester.tap(findLink('Go Pro'));
      expect(goPro, 1);
    });

    testWidgets('choosing another tile ticks once', (tester) async {
      final haptics = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'HapticFeedback.vibrate') {
              haptics.add(call.arguments as String);
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      await pumpInVogue(
        tester,
        OutfitTiles(outfits: outfits, selectedIndex: 0, onSelected: (_) {}),
      );
      await tester.tap(find.byType(PhotoSlot).first);
      await tester.tap(find.byType(PhotoSlot).at(1));
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });
  });

  group('PlanLine', () {
    testWidgets('free: what is left, then Go Pro on the highlighter', (
      tester,
    ) async {
      var goPro = 0;
      await pumpInVogue(
        tester,
        PlanLine.free(
          outfitsLeft: 9,
          makeupLooksLeft: 3,
          onGoPro: () => goPro++,
        ),
      );
      expect(
        find.textContaining(
          'Free plan · 9 outfits and 3 makeup looks left · ',
          findRichText: true,
        ),
        findsOneWidget,
      );
      final link = tester.widget<TextLink>(find.byType(TextLink));
      expect(link.highlight, isTrue);
      expect(link.style.fontSize, 12);
      final rule = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(PlanLine),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect(
        rule.decoration,
        const BoxDecoration(
          border: Border(top: BorderSide(color: InVogueColors.rule)),
        ),
      );
      await tester.tap(find.byType(TextLink));
      expect(goPro, 1);
    });

    testWidgets('counts are pluralised and run out honestly', (tester) async {
      await pumpInVogue(
        tester,
        Column(
          children: [
            PlanLine.free(outfitsLeft: 1, makeupLooksLeft: 1, onGoPro: () {}),
            PlanLine.free(outfitsLeft: 0, makeupLooksLeft: 3, onGoPro: () {}),
            PlanLine.makeup(makeupLooksLeft: 3, onGoPro: () {}),
            const PlanLine.onProList(),
          ],
        ),
      );
      for (final line in [
        'Free plan · 1 outfit and 1 makeup look left · ',
        'Free plan · no outfits left · ',
        'Free plan · 3 makeup looks left · ',
        'On the Pro list ✓',
      ]) {
        expect(
          find.textContaining(line, findRichText: true),
          findsOneWidget,
          reason: line,
        );
      }
      expect(find.byType(TextLink), findsNWidgets(3));
    });
  });
}
