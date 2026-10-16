import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph_paths.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  group('WeatherGlyphType', () {
    test('loop lengths include three cycles and the stagger', () {
      expect(WeatherGlyphType.sun.loop, const Duration(milliseconds: 7200));
      expect(
        WeatherGlyphType.cloudRain.loop,
        const Duration(milliseconds: 4000),
      );
      expect(
        WeatherGlyphType.cloudSnow.loop,
        const Duration(milliseconds: 6000),
      );
      expect(WeatherGlyphType.wind.loop, const Duration(milliseconds: 4800));
    });
  });

  test('glyph paths match the spec', () {
    final assets = Directory('../design-spec/assets/weather');
    if (!assets.existsSync()) return markTestSkipped('design-spec absent');
    for (final type in WeatherGlyphType.values) {
      final svg = File(
        '${assets.path}/${type.specName}-light.svg',
      ).readAsStringSync();
      final data = RegExp(' d="([^"]+)"').firstMatch(svg)!.group(1);
      expect(weatherStillPaths[type.specName], data, reason: type.name);
    }
    final preview = File(
      '../design-spec/components/WeatherGlyph/preview.html',
    ).readAsStringSync();
    expect(preview, contains(weatherCloudBodyPath));
    for (final (from, to) in weatherDrops) {
      expect(
        preview,
        contains(
          'x1="${from.dx.toInt()}" y1="${from.dy.toInt()}" '
          'x2="${to.dx.toInt()}" y2="${to.dy.toInt()}"',
        ),
      );
    }
    for (final flake in weatherFlakes) {
      expect(
        preview,
        contains('cx="${flake.dx.toInt()}" cy="${flake.dy.toInt()}" r="10"'),
      );
    }
  });

  group('WeatherGlyph', () {
    WeatherGlyphPainter painter(WidgetTester tester) =>
        tester
                .widget<CustomPaint>(
                  find.descendant(
                    of: find.byType(WeatherGlyph),
                    matching: find.byType(CustomPaint),
                  ),
                )
                .painter!
            as WeatherGlyphPainter;

    testWidgets('plays three cycles, then rests on its first frame', (
      tester,
    ) async {
      await pumpInVogue(tester, const WeatherGlyph(WeatherGlyphType.sun));
      expect(tester.getSize(find.byType(WeatherGlyph)), const Size.square(28));
      await tester.pump(const Duration(milliseconds: 1200));
      expect(painter(tester).loop.value, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 6100));
      expect(painter(tester).loop.value, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('a new play key replays the loop', (tester) async {
      var key = 0;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => key++),
            child: WeatherGlyph(WeatherGlyphType.cloud, playKey: key),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 8));
      expect(tester.hasRunningAnimations, isFalse);
      await tester.tap(find.byType(WeatherGlyph));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
    });

    testWidgets('stays still with reduced motion', (tester) async {
      await pumpInVogue(
        tester,
        const WeatherGlyph(WeatherGlyphType.cloudRain),
        disableAnimations: true,
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(painter(tester).loop.value, 0);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('stops when its ticker mode is muted', (tester) async {
      var enabled = true;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => enabled = false),
            child: TickerMode(
              enabled: enabled,
              child: const WeatherGlyph(WeatherGlyphType.wind),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.tap(find.byType(WeatherGlyph));
      await tester.pump();
      expect(painter(tester).loop.value, 0);
    });

    testWidgets('stops when the app leaves the foreground', (tester) async {
      await pumpInVogue(tester, const WeatherGlyph(WeatherGlyphType.cloudSnow));
      await tester.pump(const Duration(milliseconds: 400));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await tester.pump();
      expect(painter(tester).loop.value, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    testWidgets('the still variant never moves and is 22 points', (
      tester,
    ) async {
      await pumpInVogue(tester, const WeatherGlyph.still(WeatherGlyphType.sun));
      expect(tester.getSize(find.byType(WeatherGlyph)), const Size.square(22));
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.hasRunningAnimations, isFalse);
      expect(painter(tester).still, isTrue);
    });

    test('swing eases each half like a CSS keyframe', () {
      expect(WeatherGlyphPainter.swing(0), 0);
      expect(WeatherGlyphPainter.swing(0.5), 1);
      expect(WeatherGlyphPainter.swing(1), closeTo(0, 1e-9));
      expect(
        WeatherGlyphPainter.swing(0.25),
        InVogueMotion.standard.transform(0.5),
      );
    });

    testWidgets('is never announced', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(tester, const WeatherGlyph(WeatherGlyphType.sun));
      expect(
        find.descendant(
          of: find.byType(WeatherGlyph),
          matching: find.byType(ExcludeSemantics),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('WeatherLine', () {
    const line = WeatherLine(
      temperature: 54,
      feelsLike: 49,
      condition: 'Showers after 3 pm',
      glyph: WeatherGlyphType.cloudRain,
      highlight: true,
      dayLabel: 'Tomorrow',
    );

    testWidgets('sets the figure, condition and feels-like as specified', (
      tester,
    ) async {
      // Wide enough that the em-wide test font does not wrap the condition.
      await pumpInVogue(tester, line, size: const Size(800, 844));
      await tester.pump(const Duration(seconds: 5));
      final box = tester.getRect(find.byType(WeatherLine));
      final figure = tester.getRect(find.byType(TemperatureText));
      final glyph = tester.getRect(find.byType(WeatherGlyph));
      final condition = tester.getRect(find.byType(MarkedText));
      final feels = tester.getRect(find.text('Feels like 49°'));
      expect(figure.left - box.left, -4);
      expect(figure.top - box.top, 16);
      expect(box.bottom - figure.bottom, 12);
      expect(glyph.left - figure.right, 16 - 2);
      expect(condition.left - glyph.right, 6);
      expect(feels.left, glyph.left + 2);
      expect(feels.bottom, figure.bottom, reason: 'aligned to the bottom');
      expect(
        tester.widget<MarkedText>(find.byType(MarkedText)).highlight,
        isTrue,
      );
      expect(
        tester.widget<Text>(find.text('Feels like 49°')).style!.color,
        InVogueColors.graphite,
      );
    });

    testWidgets('reads as one sentence', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(tester, line);
      expect(
        find.bySemanticsLabel(
          'Tomorrow, 54 degrees, Showers after 3 pm, feels like 49.',
        ),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('54 degrees'), findsNothing);
      handle.dispose();
    });

    testWidgets('stacks the condition under the figure at large text', (
      tester,
    ) async {
      await pumpInVogue(tester, line, textScale: 2, size: const Size(320, 568));
      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
      expect(
        tester.getTopLeft(find.byType(WeatherGlyph)).dy,
        greaterThan(tester.getBottomLeft(find.byType(TemperatureText)).dy),
      );
    });

    testWidgets('a new temperature rolls up and the old one leaves', (
      tester,
    ) async {
      var temperature = 61;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => temperature = 54),
            child: WeatherLine(
              temperature: temperature,
              feelsLike: 49,
              condition: 'Showers after 3 pm',
              glyph: WeatherGlyphType.cloudRain,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 5));
      final rest = tester.getTopLeft(find.text('61°')).dy;
      await tester.tap(find.byType(WeatherLine));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getTopLeft(find.text('61°')).dy, lessThan(rest));
      expect(tester.getTopLeft(find.text('54°')).dy, greaterThan(rest));
      // Slow enough to read as one change: still under way at 400 ms.
      await tester.pump(const Duration(milliseconds: 280));
      expect(find.text('61°'), findsOneWidget);
      expect(tester.getTopLeft(find.text('54°')).dy, greaterThan(rest));
      await tester.pump(const Duration(milliseconds: 260));
      expect(find.text('61°'), findsNothing);
      expect(tester.getTopLeft(find.text('54°')).dy, rest);
    });

    testWidgets('with reduced motion the figures crossfade in place', (
      tester,
    ) async {
      var temperature = 61;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => temperature = 54),
            child: WeatherLine(
              temperature: temperature,
              feelsLike: 49,
              condition: 'Rain',
              glyph: WeatherGlyphType.cloudRain,
            ),
          ),
        ),
        disableAnimations: true,
      );
      final rest = tester.getTopLeft(find.text('61°')).dy;
      await tester.tap(find.byType(WeatherLine));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.getTopLeft(find.text('61°')).dy, rest);
      expect(tester.getTopLeft(find.text('54°')).dy, rest);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('61°'), findsNothing);
    });

    testWidgets('a new condition crossfades and only one glyph moves', (
      tester,
    ) async {
      var sunny = false;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => sunny = true),
            child: WeatherLine(
              temperature: 54,
              feelsLike: 49,
              condition: sunny ? 'Sunny all day' : 'Showers after 3 pm',
              glyph: sunny ? WeatherGlyphType.sun : WeatherGlyphType.cloudRain,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(WeatherLine));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(
        find.text('Showers after 3 pm', skipOffstage: false),
        findsNothing,
      );
      expect(find.byType(WeatherGlyph), findsNWidgets(2));
      final moving = tester
          .widgetList<CustomPaint>(
            find.descendant(
              of: find.byType(WeatherGlyph),
              matching: find.byType(CustomPaint),
            ),
          )
          .map((p) => (p.painter! as WeatherGlyphPainter).loop.value > 0);
      expect(moving.where((m) => m), hasLength(1));
      await tester.pumpAndSettle();
      expect(find.byType(WeatherGlyph), findsOneWidget);
    });
  });
}
