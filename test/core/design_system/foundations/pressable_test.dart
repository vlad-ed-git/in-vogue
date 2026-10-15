import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/design_system/design_system.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  final haptics = <String>[];

  setUp(() {
    haptics.clear();
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

  Widget control({
    VoidCallback? onTap,
    InVogueHaptic haptic = InVogueHaptic.none,
    List<PressableState>? states,
  }) => Center(
    child: Pressable(
      onTap: onTap,
      haptic: haptic,
      semanticLabel: 'Shop',
      builder: (context, state) {
        states?.add(state);
        return SizedBox(
          width: 100,
          height: 20,
          child: ColoredBox(
            color: state.pressed
                ? InVogueColors.signalPressed
                : InVogueColors.signal,
          ),
        );
      },
    ),
  );

  testWidgets('activates on tap and shows its pressed state meanwhile', (
    tester,
  ) async {
    var taps = 0;
    final states = <PressableState>[];
    await pumpInVogue(
      tester,
      control(onTap: () => taps++, states: states),
      scroll: false,
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(SizedBox).last),
    );
    await tester.pump();
    expect(states.last.pressed, isTrue);
    await gesture.up();
    await tester.pump();
    expect(states.last.pressed, isFalse);
    expect(taps, 1);
  });

  testWidgets('plays its haptic once per activation', (tester) async {
    await pumpInVogue(
      tester,
      control(onTap: () {}, haptic: InVogueHaptic.selection),
      scroll: false,
    );
    await tester.tap(find.byType(Pressable));
    expect(haptics, ['HapticFeedbackType.selectionClick']);
  });

  testWidgets('a disabled control ignores taps and says so', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpInVogue(tester, control(), scroll: false);
    await tester.tap(find.byType(Pressable), warnIfMissed: false);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Shop')),
      matchesSemantics(
        label: 'Shop',
        isButton: true,
        hasEnabledState: true,
        isFocusable: false,
      ),
    );
    handle.dispose();
  });

  testWidgets('Enter activates it and keyboard focus draws the ring', (
    tester,
  ) async {
    var taps = 0;
    await pumpInVogue(tester, control(onTap: () => taps++), scroll: false);
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(
      () => FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final ring = find.byWidgetPredicate((w) => w is FocusRing && w.visible);
    expect(ring, findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('a small control answers taps across the platform minimum', (
    tester,
  ) async {
    var taps = 0;
    await pumpInVogue(tester, control(onTap: () => taps++), scroll: false);
    final box = tester.getRect(find.byType(Pressable));
    expect(box.height, 20, reason: 'layout is unchanged');
    // 48 dp on Android: 14 points above and below a 20-point control.
    await tester.tapAt(box.topCenter - const Offset(0, 13));
    await tester.tapAt(box.bottomCenter + const Offset(0, 13));
    expect(taps, 2);
    await tester.tapAt(box.topCenter - const Offset(0, 15));
    expect(taps, 2);
  });

  testWidgets('iOS uses the 44-point minimum', (tester) async {
    var taps = 0;
    await pumpInVogue(
      tester,
      control(onTap: () => taps++),
      platform: TargetPlatform.iOS,
      scroll: false,
    );
    final box = tester.getRect(find.byType(Pressable));
    await tester.tapAt(box.topCenter - const Offset(0, 11));
    expect(taps, 1);
    await tester.tapAt(box.topCenter - const Offset(0, 13));
    expect(taps, 1);
  });
}
