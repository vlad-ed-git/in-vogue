import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/design_system/design_system.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  test('every icon is the spec’s Phosphor SVG, verbatim', () {
    final icons = Directory('../design-spec/assets/icons');
    if (!icons.existsSync()) return markTestSkipped('design-spec absent');
    for (final icon in InVogueIcons.values) {
      final svg = File('${icons.path}/${icon.specName}.svg').readAsStringSync();
      final data = RegExp(' d="([^"]+)"').allMatches(svg).single.group(1);
      expect(icon.pathData, data, reason: icon.specName);
    }
  });

  test('every icon parses into a shape inside the 256 grid', () {
    for (final icon in InVogueIcons.values) {
      final bounds = SvgPath.parse(icon.pathData).getBounds();
      expect(bounds.isEmpty, isFalse, reason: icon.name);
      expect(
        const Rect.fromLTWH(
              0,
              0,
              256,
              256,
            ).inflate(0.01).contains(bounds.topLeft) &&
            const Rect.fromLTWH(
              0,
              0,
              256,
              256,
            ).inflate(0.01).contains(bounds.bottomRight),
        isTrue,
        reason: icon.name,
      );
    }
  });

  test('parsing is cached', () {
    final data = InVogueIcons.heart.pathData;
    expect(identical(SvgPath.parse(data), SvgPath.parse(data)), isTrue);
  });

  testWidgets('draws at its size, in ink unless told otherwise', (
    tester,
  ) async {
    await pumpInVogue(
      tester,
      const Row(
        children: [
          InVogueIcon(InVogueIcons.heart),
          InVogueIcon(
            InVogueIcons.heartFill,
            size: 22,
            color: InVogueColors.signal,
          ),
        ],
      ),
    );
    final painters = tester
        .widgetList<CustomPaint>(
          find.descendant(
            of: find.byType(InVogueIcon),
            matching: find.byType(CustomPaint),
          ),
        )
        .toList();
    expect(painters.map((p) => p.size), [
      const Size.square(24),
      const Size.square(22),
    ]);
    expect(painters.map((p) => (p.painter! as GridPathPainter).color), [
      InVogueColors.ink,
      InVogueColors.signal,
    ]);
  });

  testWidgets('is silent unless it carries a label', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpInVogue(
      tester,
      const Row(
        children: [
          InVogueIcon(InVogueIcons.check),
          InVogueIcon(InVogueIcons.lock, semanticLabel: 'Part of Pro'),
        ],
      ),
    );
    expect(find.bySemanticsLabel('Part of Pro'), findsOneWidget);
    handle.dispose();
  });
}
