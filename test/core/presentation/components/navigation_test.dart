import 'dart:ui' show SemanticsRole, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  late List<String> haptics;

  setUp(() {
    haptics = [];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        });
  });

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );

  group('TopBar', () {
    testWidgets('city on the left, Your picks with a heart on the right', (
      tester,
    ) async {
      var picks = 0;
      await pumpInVogue(
        tester,
        TopBar(city: 'New York', onYourPicks: () => picks++),
      );
      expect(tester.getSize(find.byType(TopBar)), const Size(350, 44));
      expect(
        tester.widget<Text>(find.text('New York')).style!.fontWeight,
        FontWeight.w600,
      );
      expect(tester.getTopLeft(find.text('New York')).dx, 20);
      expect(tester.getTopRight(find.text('Your picks')).dx, 370);
      final heart = tester.getRect(findIcon(InVogueIcons.heart));
      expect(heart.size, const Size.square(20));
      expect(tester.getTopLeft(find.text('Your picks')).dx - heart.right, 6);
      await tester.tap(find.text('Your picks'));
      expect(picks, 1);
    });

    testWidgets('a long city wraps instead of truncating', (tester) async {
      await pumpInVogue(
        tester,
        TopBar(
          city: 'San Francisco Bay Area and Peninsula',
          onYourPicks: () {},
        ),
        size: const Size(320, 568),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      final city = tester.widget<Text>(
        find.text('San Francisco Bay Area and Peninsula'),
      );
      expect(city.maxLines, isNull);
      expect(city.overflow, isNull);
      expect(tester.getSize(find.byType(TopBar)).height, greaterThan(44));
    });
  });

  group('BackBar', () {
    testWidgets('Back pulls its caret 6 into the margin; folio on the right', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var back = 0;
      await pumpInVogue(tester, BackBar(onBack: () => back++, step: 2));
      final caret = tester.getRect(findIcon(InVogueIcons.caretLeft));
      expect(caret.left, 14);
      expect(caret.size, const Size.square(20));
      expect(tester.getTopLeft(find.text('Back')).dx - caret.right, 2);
      expect(find.text('2 / 6'), findsOneWidget);
      final folio = tester.widget<Text>(find.text('2 / 6'));
      expect(folio.style!.color, InVogueColors.graphite);
      expect(folio.style!.fontFeatures, InVogueType.tabularFigures);
      expect(tester.getTopRight(find.text('2 / 6')).dx, 370);
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      await tester.tap(find.text('Back'));
      expect(back, 1);
      handle.dispose();
    });

    testWidgets('after setup there is no folio', (tester) async {
      await pumpInVogue(tester, BackBar(onBack: () {}));
      expect(find.textContaining('/'), findsNothing);
    });

    testWidgets('Go Pro closes with an x on the right', (tester) async {
      final handle = tester.ensureSemantics();
      var closed = 0;
      await pumpInVogue(tester, BackBar.close(onClose: () => closed++));
      expect(find.text('Back'), findsNothing);
      final close = tester.getRect(findIcon(InVogueIcons.close));
      expect(close.right, 370);
      expect(close.size, const Size.square(24));
      await tester.tap(find.bySemanticsLabel('Close'));
      expect(closed, 1);
      handle.dispose();
    });
  });

  group('InVogueTabBar', () {
    testWidgets('three words; the current one is bold ink with a marker', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      InVogueTab? selected;
      tester.view.viewPadding = const FakeViewPadding(bottom: 34);
      await pumpInVogue(
        tester,
        Align(
          alignment: Alignment.bottomCenter,
          child: InVogueTabBar(
            current: InVogueTab.makeup,
            onSelected: (tab) => selected = tab,
          ),
        ),
        scroll: false,
      );
      expect(tester.getSize(find.byType(InVogueTabBar)).height, 50 + 34);
      expect(
        tester.widget<Text>(find.text('Makeup')).style,
        InVogueType.navActive,
      );
      expect(tester.widget<Text>(find.text('Home')).style, InVogueType.nav);
      final bar = tester.getRect(find.byType(InVogueTabBar));
      final marker = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == InVogueColors.ink,
        ),
      );
      expect(marker.size, const Size(32, 2));
      expect(marker.top, bar.top, reason: 'it covers the top hairline');
      expect(marker.center.dx, tester.getCenter(find.text('Makeup')).dx);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Makeup')),
        matchesSemantics(
          label: 'Makeup',
          isButton: true,
          hasSelectedState: true,
          isSelected: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
          hasTapAction: true,
        ),
      );
      await tester.tap(find.text('Settings'));
      expect(selected, InVogueTab.settings);
      expect(haptics, isEmpty, reason: 'the tab bar does not buzz');
      handle.dispose();
    });
  });

  group('DaySwitch', () {
    Widget daySwitch(int selected, ValueChanged<int> onSelected) => DaySwitch(
      labels: const ['Today', 'Tomorrow'],
      selectedIndex: selected,
      date: 'Thu 16 Oct',
      onSelected: onSelected,
    );

    Rect rule(WidgetTester tester) => tester.getRect(
      find.descendant(
        of: find.byType(DaySwitch),
        matching: find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == InVogueColors.ink,
        ),
      ),
    );

    testWidgets('lays out the spec’s 40-point box', (tester) async {
      await pumpInVogue(tester, daySwitch(1, (_) {}));
      final box = tester.getRect(find.byType(DaySwitch));
      expect(box.height, 40);
      final today = tester.getRect(find.text('Today'));
      final tomorrow = tester.getRect(find.text('Tomorrow'));
      expect(today.top - box.top, 6);
      expect(tomorrow.left - today.right, 24);
      expect(
        rule(tester),
        Rect.fromLTWH(tomorrow.left, box.bottom - 2, tomorrow.width, 2),
      );
      final date = tester.getRect(find.text('Thu 16 Oct'));
      expect(date.right, box.right);
      expect(box.bottom - date.bottom, 11);
      expect(
        tester.widget<Text>(find.text('Tomorrow')).style!.fontWeight,
        FontWeight.w700,
      );
      expect(
        tester.widget<Text>(find.text('Today')).style!.fontWeight,
        FontWeight.w500,
      );
    });

    testWidgets('the rule slides to the chosen tab over 240 ms', (
      tester,
    ) async {
      var selected = 1;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) =>
              daySwitch(selected, (i) => setState(() => selected = i)),
        ),
      );
      final start = rule(tester);
      await tester.tap(find.text('Today'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final midway = rule(tester);
      expect(midway.left, lessThan(start.left));
      expect(midway.left, greaterThan(tester.getRect(find.text('Today')).left));
      await tester.pump(const Duration(milliseconds: 200));
      expect(rule(tester).left, tester.getRect(find.text('Today')).left);
      expect(rule(tester).width, tester.getRect(find.text('Today')).width);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('with reduced motion the rule jumps', (tester) async {
      var selected = 1;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) =>
              daySwitch(selected, (i) => setState(() => selected = i)),
        ),
        disableAnimations: true,
      );
      await tester.tap(find.text('Today'));
      await tester.pump();
      expect(rule(tester).left, tester.getRect(find.text('Today')).left);
    });

    testWidgets('tapping the selected tab does nothing', (tester) async {
      var calls = 0;
      await pumpInVogue(tester, daySwitch(1, (_) => calls++));
      await tester.tap(find.text('Tomorrow'));
      expect(calls, 0);
      expect(haptics, isEmpty);
    });

    testWidgets('is a tab list; the selected tab carries the date', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(tester, daySwitch(1, (_) {}));
      final node = tester.getSemantics(find.bySemanticsLabel('Tomorrow'));
      expect(node.getSemanticsData().role, SemanticsRole.tab);
      expect(node.getSemanticsData().value, 'Thu 16 Oct');
      expect(
        node.getSemanticsData().flagsCollection.isSelected,
        Tristate.isTrue,
      );
      expect(find.bySemanticsLabel('Thu 16 Oct'), findsNothing);
      handle.dispose();
    });

    testWidgets('grows for large text and keeps the rule on its line', (
      tester,
    ) async {
      await pumpInVogue(tester, daySwitch(1, (_) {}), textScale: 2);
      expect(tester.takeException(), isNull);
      final box = tester.getRect(find.byType(DaySwitch));
      expect(box.height, greaterThan(40));
      expect(rule(tester).bottom, box.bottom);
      expect(
        tester.widget<Text>(find.text('Tomorrow')).textScaler!.scale(10),
        13,
        reason: 'display text grows at most 1.3 times',
      );
    });
  });

  group('CategoryChips', () {
    const labels = [
      'All',
      'Coats & jackets',
      'Knitwear',
      'Tops',
      'Trousers & jeans',
      'Skirts & shorts',
      'Dresses',
    ];

    Widget chips(int selected, ValueChanged<int> onSelected) => Column(
      children: [
        CategoryChips(
          labels: labels,
          selectedIndex: selected,
          onSelected: onSelected,
        ),
      ],
    );

    testWidgets('36-point square chips, 8 apart, inked edge or ink fill', (
      tester,
    ) async {
      await pumpInVogue(tester, chips(0, (_) {}), scroll: false);
      final row = tester.getRect(find.byType(CategoryChips));
      expect(row.height, 48);
      final all = tester.getRect(find.text('All'));
      final coats = tester.getRect(find.text('Coats & jackets'));
      expect(all.left, 20 + 14, reason: 'page margin plus chip padding');
      expect(coats.left - all.right, 14 + 8 + 14);
      BoxDecoration chip(String label) =>
          tester
                  .widget<DecoratedBox>(
                    find
                        .ancestor(
                          of: find.text(label),
                          matching: find.byType(DecoratedBox),
                        )
                        .first,
                  )
                  .decoration
              as BoxDecoration;
      expect(chip('All').color, InVogueColors.ink);
      expect(chip('Knitwear').color, isNull);
      expect(chip('Knitwear').border, Border.all(color: InVogueColors.ink));
      expect(
        tester.widget<Text>(find.text('All')).style!.color,
        InVogueColors.paper,
      );
      expect(
        tester
            .getSize(
              find
                  .ancestor(
                    of: find.text('Tops'),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .height,
        36,
      );
    });

    testWidgets('runs past the right edge and scrolls sideways', (
      tester,
    ) async {
      var selected = 0;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) =>
              chips(selected, (i) => setState(() => selected = i)),
        ),
        scroll: false,
      );
      expect(tester.getRect(find.text('Dresses')).left, greaterThan(390));
      await tester.drag(find.byType(CategoryChips), const Offset(-2000, 0));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('Dresses')).right, lessThan(390));
      await tester.tap(find.text('Dresses'));
      await tester.pumpAndSettle();
      expect(selected, 6);
      expect(haptics, ['HapticFeedbackType.selectionClick']);
    });

    testWidgets('chips are toggle buttons, one on at a time', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(tester, chips(2, (_) {}), scroll: false);
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('Knitwear'))
            .getSemanticsData()
            .flagsCollection
            .isToggled,
        Tristate.isTrue,
      );
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('All'))
            .getSemanticsData()
            .flagsCollection
            .isToggled,
        Tristate.isFalse,
      );
      handle.dispose();
    });
  });
}
