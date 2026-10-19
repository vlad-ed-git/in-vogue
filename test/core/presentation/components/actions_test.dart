import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  Color fill(WidgetTester tester, String label) {
    final container = tester.widget<AnimatedContainer>(
      find.ancestor(
        of: find.text(label),
        matching: find.byType(AnimatedContainer),
      ),
    );
    return (container.decoration! as BoxDecoration).color!;
  }

  Color labelColor(WidgetTester tester, String label) =>
      tester.widget<Text>(find.text(label)).style!.color!;

  group('InVogueButton', () {
    testWidgets('keeps its height when given room to grow', (tester) async {
      await pumpInVogue(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350, maxHeight: 400),
            child: InVogueButton.primary(label: 'Proceed', onPressed: () {}),
          ),
        ),
        scroll: false,
      );
      expect(
        tester.getSize(find.byType(InVogueButton)).height,
        InVogueLayout.controlHeight,
      );
    });

    testWidgets('primary is Rouge with a white label, 52 tall and full width', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        InVogueButton.primary(label: 'Shop', onPressed: () {}),
      );
      expect(tester.getSize(find.byType(InVogueButton)), const Size(350, 52));
      expect(fill(tester, 'Shop'), InVogueColors.signal);
      expect(labelColor(tester, 'Shop'), InVogueColors.onSignal);
      expect(findIcon(InVogueIcons.arrowRight), findsOneWidget);
    });

    testWidgets(
      'puts the label 18 in from the left, the icon 16 from the right',
      (tester) async {
        await pumpInVogue(
          tester,
          InVogueButton.primary(label: 'Shop', onPressed: () {}),
        );
        final button = tester.getRect(find.byType(InVogueButton));
        final label = tester.getRect(find.text('Shop'));
        final icon = tester.getRect(findIcon(InVogueIcons.arrowRight));
        expect(label.left - button.left, 18);
        expect(label.center.dy, button.center.dy);
        expect(icon.size, const Size.square(22));
        expect(button.right - icon.right, 16);
        expect(icon.center.dy, button.center.dy);
      },
    );

    testWidgets('darkens while pressed and calls back on release', (
      tester,
    ) async {
      var taps = 0;
      await pumpInVogue(
        tester,
        InVogueButton.primary(label: 'Shop', onPressed: () => taps++),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(InVogueButton)),
      );
      await tester.pumpAndSettle();
      expect(fill(tester, 'Shop'), InVogueColors.signalPressed);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(fill(tester, 'Shop'), InVogueColors.signal);
      expect(taps, 1);
    });

    testWidgets('secondary is Rose with ink; pressed is accent-pressed', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        InVogueButton.secondary(
          label: 'Try again',
          icon: InVogueIcons.retry,
          onPressed: () {},
        ),
      );
      expect(fill(tester, 'Try again'), InVogueColors.accent);
      expect(labelColor(tester, 'Try again'), InVogueColors.onAccent);
      await tester.startGesture(tester.getCenter(find.byType(InVogueButton)));
      await tester.pumpAndSettle();
      expect(fill(tester, 'Try again'), InVogueColors.accentPressed);
    });

    testWidgets('on a Rose notice the secondary button is paper', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        InVogueButton.secondary(
          label: 'Try again',
          onRose: true,
          onPressed: () {},
        ),
      );
      expect(fill(tester, 'Try again'), InVogueColors.paper);
    });

    testWidgets('disabled is studio with a graphite label and ignores taps', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(
        tester,
        const InVogueButton.primary(label: 'Continue', onPressed: null),
      );
      expect(fill(tester, 'Continue'), InVogueColors.studio);
      expect(labelColor(tester, 'Continue'), InVogueColors.graphite);
      expect(
        tester.getSemantics(find.text('Continue')),
        matchesSemantics(
          label: 'Continue',
          isButton: true,
          hasEnabledState: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('compact is 44 tall with an 18-point icon', (tester) async {
      await pumpInVogue(
        tester,
        SizedBox(
          width: 169,
          child: InVogueButton.secondary(
            label: 'Buy',
            icon: InVogueIcons.arrowUpRight,
            compact: true,
            onPressed: () {},
          ),
        ),
      );
      expect(tester.getSize(find.byType(InVogueButton)).height, 44);
      expect(
        tester.getSize(findIcon(InVogueIcons.arrowUpRight)),
        const Size.square(18),
      );
      expect(
        tester.getTopLeft(find.text('Buy')).dx -
            tester.getTopLeft(find.byType(InVogueButton)).dx,
        14,
      );
    });

    testWidgets('a long label wraps and the button grows instead of clipping', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        InVogueButton.primary(
          label: 'Choose a different photo from your Gallery',
          onPressed: () {},
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(InVogueButton)).height,
        greaterThan(52),
      );
    });

    testWidgets('Enter activates a focused button', (tester) async {
      var taps = 0;
      await pumpInVogue(
        tester,
        InVogueButton.primary(label: 'Next', onPressed: () => taps++),
      );
      tester
          .widget<FocusableActionDetector>(
            find.descendant(
              of: find.byType(InVogueButton),
              matching: find.byType(FocusableActionDetector),
            ),
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });
  });

  group('TextLink', () {
    testWidgets('is underlined ink in the link style and reads as a link', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpInVogue(
        tester,
        Align(
          alignment: Alignment.topLeft,
          child: TextLink(label: 'Change', onTap: () => taps++),
        ),
      );
      final text = tester.widget<MarkedText>(find.byType(MarkedText));
      expect(text.underline, isTrue);
      expect(text.highlight, isFalse);
      expect(text.style.fontSize, 15);
      expect(text.style.fontWeight, FontWeight.w500);
      expect(text.style.color, InVogueColors.ink);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Change')),
        matchesSemantics(
          label: 'Change',
          isLink: true,
          hasTapAction: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      await tester.tap(find.byType(TextLink));
      expect(taps, 1);
      handle.dispose();
    });

    testWidgets('a 20-point link answers taps across 48 points', (
      tester,
    ) async {
      var taps = 0;
      await pumpInVogue(
        tester,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            TextLink(label: 'Skip', onTap: () => taps++),
            const SizedBox(height: 40),
          ],
        ),
      );
      final link = tester.getRect(find.byType(TextLink));
      expect(link.height, 20);
      await tester.tapAt(link.topCenter - const Offset(0, 13));
      await tester.tapAt(link.bottomCenter + const Offset(0, 13));
      expect(taps, 2);
    });
  });

  group('LoveToggle', () {
    late List<String> haptics;
    final scaleIn = find.descendant(
      of: find.byType(LoveToggle),
      matching: find.byType(ScaleTransition),
    );

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

    Widget harness({
      required bool loved,
      required ValueChanged<bool> onChanged,
    }) => Align(
      alignment: Alignment.topLeft,
      child: LoveToggle(
        loved: loved,
        onChanged: onChanged,
        pieceLabel: 'Oversized Mac Coat, Cornstalk',
      ),
    );

    testWidgets('is an ink outline in a 44-point area until loved', (
      tester,
    ) async {
      await pumpInVogue(tester, harness(loved: false, onChanged: (_) {}));
      expect(tester.getSize(find.byType(LoveToggle)), const Size.square(44));
      final heart = tester.widget<Icon>(findIcon(InVogueIcons.heart));
      expect(heart.size, 22);
      expect(heart.color, InVogueColors.ink);
    });

    testWidgets('loved is the Rouge filled heart, read as Loved', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInVogue(tester, harness(loved: true, onChanged: (_) {}));
      final heart = tester.widget<Icon>(findIcon(InVogueIcons.heartFill));
      expect(heart.color, InVogueColors.signal);
      expect(
        tester.getSemantics(
          find.bySemanticsLabel('Love Oversized Mac Coat, Cornstalk'),
        ),
        matchesSemantics(
          label: 'Love Oversized Mac Coat, Cornstalk',
          value: 'Loved',
          isButton: true,
          hasToggledState: true,
          isToggled: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
          isFocusable: true,
          hasFocusAction: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('loving pops once with a light haptic; removing is silent', (
      tester,
    ) async {
      var loved = false;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => harness(
            loved: loved,
            onChanged: (value) => setState(() => loved = value),
          ),
        ),
      );
      await tester.tap(find.byType(LoveToggle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      final scale = tester.widget<ScaleTransition>(scaleIn);
      expect(scale.scale.value, closeTo(1.2, 0.01));
      await tester.pumpAndSettle();
      expect(scale.scale.value, 1);
      expect(loved, isTrue);
      expect(haptics, ['HapticFeedbackType.lightImpact']);

      await tester.tap(find.byType(LoveToggle));
      await tester.pump();
      expect(loved, isFalse);
      expect(haptics, hasLength(1));
      expect(tester.widget<ScaleTransition>(scaleIn).scale.value, 1);
    });

    testWidgets('with reduced motion the heart only fills', (tester) async {
      var loved = false;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => harness(
            loved: loved,
            onChanged: (value) => setState(() => loved = value),
          ),
        ),
        disableAnimations: true,
      );
      await tester.tap(find.byType(LoveToggle));
      await tester.pump(const Duration(milliseconds: 80));
      expect(tester.widget<ScaleTransition>(scaleIn).scale.value, 1);
      expect(findIcon(InVogueIcons.heartFill), findsOneWidget);
    });
  });
}
