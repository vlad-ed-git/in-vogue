import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  group('Kicker', () {
    testWidgets('sets capitals and tracking, reads sentence case', (
      tester,
    ) async {
      await pumpInVogue(tester, const Kicker('Workday'));
      final text = tester.widget<Text>(find.text('WORKDAY'));
      expect(text.style!.letterSpacing, 1.2);
      expect(text.style!.fontWeight, FontWeight.w700);
      expect(text.semanticsLabel, 'Workday');
    });

    testWidgets('drops capitals and tracking in Chinese', (tester) async {
      await pumpInVogue(
        tester,
        const Kicker('工作日'),
        locale: const Locale('zh'),
      );
      expect(tester.widget<Text>(find.text('工作日')).style!.letterSpacing, 0);
    });
  });

  group('TemperatureText', () {
    testWidgets('sets the degree sign apart and reads degrees', (tester) async {
      await pumpInVogue(tester, const TemperatureText(54));
      final text = tester.widget<Text>(find.byType(Text));
      final span = text.textSpan! as TextSpan;
      expect(span.text, '54');
      expect(span.style!.fontFamily, InVogueType.displayFamily);
      final degree = span.children!.single as TextSpan;
      expect(degree.text, '°');
      expect(degree.style!.fontFamily, InVogueType.textFamily);
      expect(degree.style!.fontWeight, FontWeight.w200);
      expect(text.semanticsLabel, '54 degrees');
    });

    testWidgets('uses a true minus sign below zero', (tester) async {
      await pumpInVogue(tester, const TemperatureText(-3));
      expect(find.text('−3°'), findsOneWidget);
      expect(find.bySemanticsLabel('-3 degrees'), findsOneWidget);
    });

    testWidgets('grows with the text size only up to 1.3 times', (
      tester,
    ) async {
      await pumpInVogue(tester, const TemperatureText(54), textScale: 2);
      final text = tester.widget<Text>(find.byType(Text));
      expect(text.textScaler!.scale(10), 13);
    });
  });

  group('Swatch', () {
    testWidgets('is a 12 or 28 point dot', (tester) async {
      await pumpInVogue(
        tester,
        const Row(
          children: [
            Swatch(color: Color(0xFFC5B095)),
            Swatch(
              color: Color(0xFF17224F),
              size: Swatch.large,
              selected: true,
            ),
          ],
        ),
      );
      final sizes = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(Swatch),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((paint) => paint.size)
          .toList();
      expect(sizes, [const Size.square(12), const Size.square(28)]);
    });

    test('repaints only when its colour or selection changes', () {
      const a = SwatchPainter(color: Color(0xFF000000), selected: false);
      expect(
        a.shouldRepaint(
          const SwatchPainter(color: Color(0xFF000000), selected: false),
        ),
        isFalse,
      );
      expect(
        a.shouldRepaint(
          const SwatchPainter(color: Color(0xFF000000), selected: true),
        ),
        isTrue,
      );
    });
  });

  group('PhotoSlot', () {
    testWidgets('keeps a 4:5 Rose frame until the photo arrives', (
      tester,
    ) async {
      await pumpInVogue(tester, const SizedBox(width: 108, child: PhotoSlot()));
      expect(tester.getSize(find.byType(PhotoSlot)), const Size(108, 135));
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(PhotoSlot),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        InVogueColors.accent,
      );
    });

    testWidgets('the check badge is a 22-point ink square, 6 in', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        const SizedBox(
          width: 108,
          child: PhotoSlot(overlay: CheckBadgeOverlay(semanticLabel: 'shown')),
        ),
      );
      final slot = tester.getRect(find.byType(PhotoSlot));
      final badge = tester.getRect(find.byType(CheckBadge));
      expect(badge.size, const Size.square(22));
      expect(badge.topRight, slot.topRight + const Offset(-6, 6));
      expect(find.bySemanticsLabel('shown'), findsOneWidget);
    });
  });

  group('layout blocks', () {
    testWidgets('the page margin narrows below 360 points', (tester) async {
      for (final (width, margin) in [(390.0, 20.0), (320.0, 16.0)]) {
        await pumpInVogue(
          tester,
          const PageMargin(child: SizedBox(height: 10, width: double.infinity)),
          size: Size(width, 844),
          scroll: false,
        );
        expect(
          tester.getTopLeft(find.byType(SizedBox).last).dx,
          margin,
          reason: 'at $width',
        );
      }
    });

    testWidgets('a section heading opens 40 points down, 12 over content', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(
        tester,
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [SectionHeading('About this outfit'), SizedBox(height: 1)],
        ),
      );
      final heading = tester.getRect(find.byType(SectionHeading));
      final text = tester.getRect(find.text('About this outfit'));
      expect(text.top - heading.top, 40);
      expect(heading.bottom - text.bottom, 12);
      expect(
        tester.getSemantics(find.text('About this outfit')),
        matchesSemantics(label: 'About this outfit', isHeader: true),
      );
      handle.dispose();
    });
  });

  group('InVogueFormat', () {
    setUpAll(initializeDateFormatting);
    final evening = DateTime(2025, 10, 16, 21, 12);
    final three = DateTime(2025, 10, 16, 15);

    test('writes English dates and times as the voice guide does', () {
      expect(InVogueFormat.shortDate(evening, 'en'), 'Thu 16 Oct');
      expect(InVogueFormat.time(three, 'en'), '3 pm');
      expect(InVogueFormat.time(evening, 'en'), '9:12 pm');
      expect(InVogueFormat.time(DateTime(2025, 10, 16), 'en'), '12 am');
      expect(
        InVogueFormat.time(DateTime(2025, 10, 16, 12, 5), 'en'),
        '12:05 pm',
      );
    });

    test('follows Spanish and Chinese conventions', () {
      expect(InVogueFormat.time(three, 'es'), '15:00');
      expect(InVogueFormat.shortDate(evening, 'zh'), '10月16日 周四');
      expect(InVogueFormat.time(evening, 'zh'), '21:12');
    });
  });
}
