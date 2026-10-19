import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  RenderMarkedText render(WidgetTester tester) =>
      tester.renderObject<RenderMarkedText>(
        find.descendant(
          of: find.byType(MarkedText),
          matching: find.byWidgetPredicate(
            (w) => w.runtimeType.toString() == '_MarkedTextLeaf',
          ),
        ),
      );

  testWidgets('the highlighter covers the type box and 4 points beyond', (
    tester,
  ) async {
    await pumpInVogue(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: MarkedText(
          'Showers',
          style: InVogueType.bodyStrong,
          highlight: true,
        ),
      ),
    );
    final text = render(tester);
    // The test font's ascent and descent fill the 17-point em; the 24-point
    // line adds 3.5 points above and below it.
    expect(text.size, const Size(7 * 17, 24));
    expect(text.highlightRects, [
      const Rect.fromLTRB(-4, 3.5, 7 * 17 + 4, 20.5),
    ]);
    expect(text.underlineRects, isEmpty);
  });

  testWidgets('a wrapped highlight is repeated on every line', (tester) async {
    await pumpInVogue(
      tester,
      const SizedBox(
        width: 100,
        child: MarkedText(
          'Snow from noon',
          style: InVogueType.body,
          highlight: true,
        ),
      ),
    );
    expect(render(tester).highlightRects, hasLength(greaterThan(1)));
  });

  testWidgets('a link underline is 1 point thick, 3 below the baseline', (
    tester,
  ) async {
    await pumpInVogue(
      tester,
      const Align(
        alignment: Alignment.topLeft,
        child: MarkedText('Change', style: InVogueType.link, underline: true),
      ),
    );
    final text = render(tester);
    final painter = TextPainter(
      text: const TextSpan(text: 'Change', style: InVogueType.link),
      textDirection: TextDirection.ltr,
    )..layout();
    final baseline = painter.computeDistanceToActualBaseline(
      TextBaseline.alphabetic,
    );
    painter.dispose();
    expect(text.underlineRects, [Rect.fromLTWH(0, baseline + 3, 6 * 15, 1)]);
  });

  testWidgets('reads its words', (tester) async {
    await pumpInVogue(
      tester,
      const MarkedText('Go Pro', style: InVogueType.caption, underline: true),
    );
    expect(find.bySemanticsLabel('Go Pro'), findsOneWidget);
  });
}
