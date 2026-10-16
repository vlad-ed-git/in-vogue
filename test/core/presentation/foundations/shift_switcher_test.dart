import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  Widget switcher(String text, int direction) => ShiftSwitcher(
    direction: direction,
    child: Text(text, key: ValueKey(text)),
  );

  Future<void> pumpSwitch(
    WidgetTester tester, {
    required int direction,
    bool disableAnimations = false,
  }) async {
    var text = 'Today';
    await pumpInVogue(
      tester,
      StatefulBuilder(
        builder: (context, setState) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => text = 'Tomorrow'),
          child: SizedBox(width: 300, child: switcher(text, direction)),
        ),
      ),
      disableAnimations: disableAnimations,
    );
    await tester.tap(find.byType(ShiftSwitcher));
    await tester.pump();
  }

  double opacityOf(WidgetTester tester, String text) => tester
      .widget<Opacity>(
        find
            .ancestor(of: find.text(text), matching: find.byType(Opacity))
            .first,
      )
      .opacity;

  testWidgets('moving forward, the old leaves to the start, the new comes '
      'from the end', (tester) async {
    await pumpSwitch(tester, direction: 1);
    final left = tester.getTopLeft(find.byType(ShiftSwitcher)).dx;
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.getTopLeft(find.text('Today')).dx, lessThan(left));
    expect(opacityOf(tester, 'Tomorrow'), 0);
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('Today'), findsOneWidget);
    expect(opacityOf(tester, 'Today'), 0);
    expect(tester.getTopLeft(find.text('Tomorrow')).dx, greaterThan(left));
    expect(opacityOf(tester, 'Tomorrow'), greaterThan(0));
    await tester.pump(const Duration(milliseconds: 160));
    expect(find.text('Today'), findsNothing);
    expect(tester.getTopLeft(find.text('Tomorrow')).dx, left);
    expect(opacityOf(tester, 'Tomorrow'), 1);
  });

  testWidgets('moving back, the new one comes from the start', (tester) async {
    await pumpSwitch(tester, direction: -1);
    final left = tester.getTopLeft(find.byType(ShiftSwitcher)).dx;
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getTopLeft(find.text('Tomorrow')).dx, lessThan(left));
  });

  testWidgets('without a direction it crossfades in place', (tester) async {
    await pumpSwitch(tester, direction: 0);
    final left = tester.getTopLeft(find.byType(ShiftSwitcher)).dx;
    await tester.pump(const Duration(milliseconds: 220));
    expect(tester.getTopLeft(find.text('Tomorrow')).dx, left);
    expect(tester.getTopLeft(find.text('Today')).dx, left);
  });

  testWidgets('with reduced motion it crossfades in 240 ms', (tester) async {
    await pumpSwitch(tester, direction: 1, disableAnimations: true);
    final left = tester.getTopLeft(find.byType(ShiftSwitcher)).dx;
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.getTopLeft(find.text('Tomorrow')).dx, left);
    await tester.pump(const Duration(milliseconds: 140));
    expect(find.text('Today'), findsNothing);
  });
}
