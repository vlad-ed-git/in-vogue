import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  group('Notice', () {
    BoxDecoration band(WidgetTester tester) =>
        tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(Notice),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration;

    testWidgets('location off: map pin, the reason, Open settings', (
      tester,
    ) async {
      var opened = 0;
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) => Notice.locationOff(
            context: context,
            onOpenSettings: () => opened++,
          ),
        ),
      );
      expect(band(tester).color, InVogueColors.accent);
      expect(band(tester).border, isNull);
      expect(findIcon(InVogueIcons.mapPin), findsOneWidget);
      expect(
        find.text('In Vogue needs your location for the weather.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Open settings'));
      expect(opened, 1);
    });

    testWidgets('a failed try-on is an alert with a paper Try again', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var retried = 0;
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) =>
              Notice.tryOnFailed(context: context, onRetry: () => retried++),
        ),
      );
      final border = band(tester).border! as Border;
      expect(border.top, const BorderSide(color: InVogueColors.ink, width: 2));
      final warning = tester.widget<Icon>(findIcon(InVogueIcons.warning));
      expect(warning.color, InVogueColors.ink, reason: 'no error red');
      final button = tester.widget<InVogueButton>(find.byType(InVogueButton));
      expect(button.kind, InVogueButtonKind.secondary);
      expect(button.onRose, isTrue);
      expect(button.icon, InVogueIcons.retry);
      expect(
        find.text('We couldn’t dress you this time. Your photo is fine.'),
        findsOneWidget,
      );
      final semantics = tester.widget<Semantics>(
        find
            .descendant(
              of: find.byType(Notice),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.liveRegion, isTrue);
      await tester.tap(find.text('Try again'));
      expect(retried, 1);
      handle.dispose();
    });

    testWidgets('lays out icon, 12 gap, text, 12 gap, action in 16 padding', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) =>
              Notice.locationOff(context: context, onOpenSettings: () {}),
        ),
      );
      final notice = tester.getRect(find.byType(Notice));
      final icon = tester.getRect(findIcon(InVogueIcons.mapPin));
      final text = tester.getRect(
        find.text('In Vogue needs your location for the weather.'),
      );
      final button = tester.getRect(find.byType(InVogueButton));
      expect(icon.topLeft - notice.topLeft, const Offset(16, 16));
      expect(icon.size, const Size.square(24));
      expect(text.left - icon.right, 12);
      expect(text.top, icon.top);
      expect(button.top - text.bottom, 12);
      expect(notice.bottom - button.bottom, 16);
      expect(notice.right - button.right, 16);
    });

    testWidgets('wraps at 200% text on a small phone without clipping', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) =>
              Notice.tryOnFailed(context: context, onRetry: () {}),
        ),
        size: const Size(320, 568),
        textScale: 2,
        locale: const Locale('es'),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Reintentar'), findsOneWidget);
    });
  });

  group('InVogueSheet', () {
    Widget opener({ValueChanged<String?>? onResult}) => Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          final result = await showInVogueSheet<String>(
            context: context,
            builder: (context) => InVogueSheet(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const InVogueSheetHeader(
                    title: 'Tomorrow is',
                    subtitle: 'Thursday 16 October',
                  ),
                  for (final option in ['Work', 'Casual'])
                    InVogueSheetOption(
                      label: option,
                      selected: option == 'Work',
                      onTap: () => Navigator.of(context).pop(option),
                    ),
                ],
              ),
            ),
          );
          onResult?.call(result);
        },
        child: const Text('Open'),
      ),
    );

    testWidgets('rises over the veil in 280 ms and returns the choice', (
      tester,
    ) async {
      String? result;
      await pumpInVogue(tester, opener(onResult: (r) => result = r));
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));
      final midway = tester.getTopLeft(find.byType(InVogueSheet)).dy;
      await tester.pump(const Duration(milliseconds: 140));
      final settled = tester.getTopLeft(find.byType(InVogueSheet)).dy;
      expect(midway, greaterThan(settled));
      expect(tester.getBottomLeft(find.byType(InVogueSheet)).dy, 844);
      final barrier = tester.widget<ModalBarrier>(
        find.byType(ModalBarrier).last,
      );
      expect(barrier.color, InVogueColors.veil);

      await tester.tap(find.text('Casual'));
      await tester.pumpAndSettle();
      expect(result, 'Casual');
      expect(find.byType(InVogueSheet), findsNothing);
    });

    testWidgets('marks the current option with a check and bold words', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(tester, opener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(find.text('Work')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(
        tester.widget<Text>(find.text('Casual')).style!.fontWeight,
        FontWeight.w400,
      );
      expect(findIcon(InVogueIcons.check), findsOneWidget);
      expect(tester.getSize(find.byType(InVogueSheetOption).first).height, 56);
      expect(
        tester.getSemantics(find.text('Work')),
        matchesSemantics(
          label: 'Work',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('has a 36 × 4 grabber, page margins and the safe area', (
      tester,
    ) async {
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      await pumpInVogue(tester, opener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final sheet = tester.getRect(find.byType(InVogueSheet));
      final title = tester.getRect(find.text('Tomorrow is'));
      expect(title.left - sheet.left, 20);
      // 12 top padding, 4 grabber, 16 gap.
      expect(title.top - sheet.top, 32);
      final last = tester.getRect(find.byType(InVogueSheetOption).last);
      expect(sheet.bottom - last.bottom, 46);
    });

    testWidgets('closes when the veil is tapped or the sheet is flung down', (
      tester,
    ) async {
      await pumpInVogue(tester, opener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(195, 40));
      await tester.pumpAndSettle();
      expect(find.byType(InVogueSheet), findsNothing);

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.fling(find.text('Tomorrow is'), const Offset(0, 300), 1500);
      await tester.pumpAndSettle();
      expect(find.byType(InVogueSheet), findsNothing);
    });

    testWidgets('a short drag springs back', (tester) async {
      await pumpInVogue(tester, opener());
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      final top = tester.getTopLeft(find.byType(InVogueSheet)).dy;
      await tester.drag(find.text('Tomorrow is'), const Offset(0, 20));
      await tester.pumpAndSettle();
      expect(find.byType(InVogueSheet), findsOneWidget);
      expect(tester.getTopLeft(find.byType(InVogueSheet)).dy, top);
    });

    testWidgets('with reduced motion it fades instead of sliding', (
      tester,
    ) async {
      await pumpInVogue(tester, opener(), disableAnimations: true);
      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.getBottomLeft(find.byType(InVogueSheet)).dy, 844);
      final fade = tester.widget<FadeTransition>(
        find
            .ancestor(
              of: find.byType(InVogueSheet),
              matching: find.byType(FadeTransition),
            )
            .first,
      );
      expect(fade.opacity.value, closeTo(100 / 280, 0.01));
      await tester.pump(const Duration(milliseconds: 180));
      expect(fade.opacity.value, 1);
    });
  });
}
