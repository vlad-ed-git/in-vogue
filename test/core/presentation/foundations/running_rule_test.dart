import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  Finder bar() => find.descendant(
    of: find.byType(RunningRule),
    matching: find.byWidgetPredicate(
      (widget) => widget is ColoredBox && widget.color == InVogueColors.ink,
    ),
  );

  Future<void> pumpRule(
    WidgetTester tester, {
    bool disableAnimations = false,
    Widget rule = const RunningRule(),
  }) => pumpInVogue(
    tester,
    Center(child: SizedBox(width: 300, child: rule)),
    disableAnimations: disableAnimations,
    scroll: false,
  );

  testWidgets('a 2-point bar a third wide runs from the start to the end', (
    tester,
  ) async {
    await pumpRule(tester);
    final left = tester.getTopLeft(find.byType(RunningRule)).dx;
    expect(tester.getSize(find.byType(RunningRule)).height, 2);
    expect(tester.getSize(bar()).width, 100);
    expect(tester.getTopLeft(bar()).dx, left - 100);

    await tester.pump(InVogueMotion.run ~/ 2);
    expect(tester.getTopLeft(bar()).dx, closeTo(left + 100, 1));

    await tester.pump(InVogueMotion.run ~/ 2 - const Duration(milliseconds: 1));
    expect(tester.getTopLeft(bar()).dx, closeTo(left + 300, 1));

    // And again from the start.
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.getTopLeft(bar()).dx, closeTo(left - 100, 1));
  });

  testWidgets('with reduced motion the bar fills the width and fades', (
    tester,
  ) async {
    await pumpRule(tester, disableAnimations: true);
    final left = tester.getTopLeft(find.byType(RunningRule)).dx;
    expect(tester.getSize(bar()).width, 300);
    expect(tester.getTopLeft(bar()).dx, left);
    double opacity() => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(RunningRule),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;
    expect(opacity(), closeTo(0.25, 0.01));
    await tester.pump(InVogueMotion.run);
    expect(opacity(), closeTo(1, 0.01));
    await tester.pump(InVogueMotion.run);
    expect(opacity(), closeTo(0.25, 0.01));
  });

  testWidgets('standing in for content, it runs over a hairline', (
    tester,
  ) async {
    await pumpRule(tester, rule: const RunningRule.content());
    expect(
      find.descendant(
        of: find.byType(RunningRule),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == InVogueColors.rule,
        ),
      ),
      findsOneWidget,
    );
    expect(bar(), findsOneWidget);
  });

  testWidgets('takes the colour it is given', (tester) async {
    await pumpRule(
      tester,
      rule: const RunningRule(color: InVogueColors.onSignal),
    );
    expect(
      find.descendant(
        of: find.byType(RunningRule),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is ColoredBox && widget.color == InVogueColors.onSignal,
        ),
      ),
      findsOneWidget,
    );
  });
}
