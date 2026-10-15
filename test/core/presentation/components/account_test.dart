import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  group('SettingsRow', () {
    testWidgets('name, value and action on a hairline row', (tester) async {
      var replaced = 0;
      await pumpInVogue(
        tester,
        SettingsRows(
          children: [
            SettingsRow(
              title: 'Body photo',
              value: 'Used to dress you',
              action: 'Replace',
              onAction: () => replaced++,
            ),
          ],
        ),
        size: const Size(800, 844),
      );
      // Hairline, 12, title 20, 2, value 20, 12; 56 is only the minimum.
      final row = tester.getRect(find.byType(SettingsRow));
      expect(row.height, 67);
      expect(
        tester.widget<Text>(find.text('Used to dress you')).style!.color,
        InVogueColors.graphite,
      );
      expect(tester.getTopRight(findLink('Replace')).dx, 780);
      await tester.tap(findLink('Replace'));
      expect(replaced, 1);
      final list = tester.getRect(find.byType(SettingsRows));
      expect(list.height, 67 + 1, reason: 'closing hairline');
    });

    testWidgets('a row without a value is 56 tall', (tester) async {
      await pumpInVogue(tester, const SettingsRow(title: 'Language'));
      expect(tester.getSize(find.byType(SettingsRow)).height, 56);
    });

    testWidgets('the profile row leads with a 56-point photo', (tester) async {
      await pumpInVogue(
        tester,
        SettingsRow.profile(
          title: 'Maya',
          value: 'Signed in with Apple',
          avatar: testImage,
          action: 'Edit',
          onAction: () {},
        ),
      );
      final avatar = tester.getRect(find.byType(PhotoSlot));
      expect(avatar.size, const Size.square(56));
      expect(tester.getTopLeft(find.text('Maya')).dx - avatar.right, 12);
    });

    testWidgets('log out and delete are whole-row ink commands', (
      tester,
    ) async {
      final taps = <String>[];
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) => SettingsRows(
            children: [
              SettingsRow.logOut(context, () => taps.add('out')),
              SettingsRow.deleteAccount(context, () => taps.add('delete')),
            ],
          ),
        ),
      );
      expect(findIcon(InVogueIcons.signOut), findsOneWidget);
      expect(
        tester.widget<Icon>(findIcon(InVogueIcons.trash)).color,
        InVogueColors.ink,
        reason: 'no red',
      );
      expect(
        tester.widget<Text>(find.text('Delete account')).style!.color,
        InVogueColors.ink,
      );
      await tester.tap(find.byType(SettingsRow).first);
      await tester.tapAt(
        tester.getCenter(find.byType(SettingsRow).last) + const Offset(120, 0),
      );
      expect(taps, ['out', 'delete']);
    });
  });

  group('ProOffer', () {
    testWidgets('name, four benefits, the price and Go Pro', (tester) async {
      var goPro = 0;
      await pumpInVogue(tester, ProOffer(onGoPro: () => goPro++));
      expect(find.text('In Vogue Pro'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('In Vogue Pro')).style,
        InVogueType.headline,
      );
      for (final benefit in [
        'A new outfit every day',
        'Other outfits to choose from',
        'The whole collection to browse',
        'Makeup for every outfit',
      ]) {
        expect(find.text(benefit), findsOneWidget);
      }
      expect(findIcon(InVogueIcons.check), findsNWidgets(4));
      expect(
        tester
            .widget<Text>(find.text('\$7.99 a month · or \$59.99 a year'))
            .style,
        InVogueType.figure,
      );
      await tester.tap(find.text('Go Pro'));
      expect(goPro, 1);
    });
  });

  group('ProConfirmation', () {
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

    DrawnCheckPainter painter(WidgetTester tester) =>
        tester
                .widget<CustomPaint>(
                  find
                      .descendant(
                        of: find.byType(ProConfirmation),
                        matching: find.byType(CustomPaint),
                      )
                      .first,
                )
                .painter!
            as DrawnCheckPainter;

    double wordsOpacity(WidgetTester tester) => tester
        .widget<FadeTransition>(
          find.descendant(
            of: find.byType(ProConfirmation),
            matching: find.byType(FadeTransition),
          ),
        )
        .opacity
        .value;

    testWidgets('draws the check, then fades the words in', (tester) async {
      var back = 0;
      await pumpInVogue(tester, ProConfirmation(onBack: () => back++));
      expect(painter(tester).progress.value, 0);
      expect(wordsOpacity(tester), 0);
      await tester.pump(const Duration(milliseconds: 300));
      expect(painter(tester).progress.value, greaterThan(0));
      expect(wordsOpacity(tester), 0);
      expect(haptics, isEmpty);
      await tester.pump(const Duration(milliseconds: 301));
      expect(painter(tester).progress.value, 1);
      expect(haptics, ['HapticFeedbackType.mediumImpact']);
      await tester.pumpAndSettle();
      expect(wordsOpacity(tester), 1);
      expect(find.text('You’re on the list.'), findsOneWidget);
      expect(
        find.text('Pro opens soon, and you’ll be the first to know.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Back to In Vogue'));
      expect(back, 1);
    });

    testWidgets('with reduced motion the check is shown drawn', (tester) async {
      await pumpInVogue(
        tester,
        ProConfirmation(onBack: () {}),
        disableAnimations: true,
      );
      expect(painter(tester).progress.value, 1);
      expect(wordsOpacity(tester), 1);
    });

    test('the stroke completes at 80% of the dash, as in CSS', () {
      final metric =
          (Path()
                ..moveTo(14, 38)
                ..lineTo(29, 52)
                ..lineTo(58, 20))
              .computeMetrics()
              .single;
      expect(metric.length / DrawnCheckPainter.dash, closeTo(0.796, 0.001));
    });
  });
}
