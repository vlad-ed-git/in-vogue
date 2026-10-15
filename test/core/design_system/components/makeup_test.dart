import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/design_system/design_system.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  group('MakeupStep', () {
    testWidgets('number, text and a 96-point picture on a 40|text|96 grid', (
      tester,
    ) async {
      var opened = 0;
      await pumpInVogue(
        tester,
        MakeupStep(
          number: 2,
          title: 'Warm the cheeks',
          instructions: 'Tap a soft peach blush on the apples of your cheeks.',
          product: 'Cream blush',
          picture: testImage,
          onPictureTap: () => opened++,
        ),
      );
      final number = tester.getRect(find.text('2'));
      final title = tester.getRect(find.text('Warm the cheeks'));
      final picture = tester.getRect(find.byType(PhotoSlot));
      expect(title.left - number.left, 40 + 12);
      expect(picture.size, const Size.square(96));
      expect(picture.right, 370);
      expect(picture.top, title.top);
      expect(
        tester.widget<Text>(find.text('2')).style!.fontFamily,
        InVogueType.displayFamily,
      );
      expect(find.text('Cream blush'), findsOneWidget);
      expect(find.text('Preparing'), findsNothing);
      await tester.tap(find.byType(PhotoSlot));
      expect(opened, 1);
    });

    testWidgets('a weather note joins the product line', (tester) async {
      await pumpInVogue(
        tester,
        MakeupStep(
          number: 4,
          title: 'Define the lashes',
          product: 'Waterproof mascara',
          note: 'showers after 3 pm',
          picture: testImage,
        ),
      );
      expect(
        find.text('Waterproof mascara · showers after 3 pm'),
        findsOneWidget,
      );
    });

    testWidgets('pending: graphite, Preparing and an empty Rose square', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        const MakeupStep(number: 5, title: 'Finish the lips'),
      );
      expect(find.text('Preparing'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Finish the lips')).style!.color,
        InVogueColors.graphite,
      );
      final slot = tester.widget<PhotoSlot>(find.byType(PhotoSlot));
      expect(slot.image, isNull);
      expect(slot.background, InVogueColors.accent);
    });

    testWidgets('the picture crossfades in when it arrives', (tester) async {
      ImageProvider? picture;
      await pumpInVogue(
        tester,
        StatefulBuilder(
          builder: (context, setState) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => setState(() => picture = testImage),
            child: MakeupStep(
              number: 1,
              title: 'Even the skin',
              picture: picture,
            ),
          ),
        ),
      );
      await tester.tap(find.byType(MakeupStep));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(find.byType(PhotoSlot), findsNWidgets(2));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoSlot), findsOneWidget);
      expect(find.text('Preparing'), findsNothing);
    });
  });

  group('BeforeAfter', () {
    final after = otherTestImage;

    testWidgets('shows After once ready and switches to Before', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        BeforeAfter(before: testImage, after: after, sentence: 'Soft peach.'),
      );
      expect(tester.widget<DaySwitch>(find.byType(DaySwitch)).selectedIndex, 1);
      expect(tester.widget<PhotoSlot>(find.byType(PhotoSlot)).image, after);
      expect(find.text('Soft peach.'), findsOneWidget);
      await tester.tap(find.text('Before'));
      await tester.pumpAndSettle();
      expect(tester.widget<PhotoSlot>(find.byType(PhotoSlot)).image, testImage);
    });

    testWidgets('without the finished look only Before shows', (tester) async {
      await pumpInVogue(tester, BeforeAfter(before: testImage));
      await tester.tap(find.text('After'));
      await tester.pumpAndSettle();
      expect(tester.widget<DaySwitch>(find.byType(DaySwitch)).selectedIndex, 0);
      expect(tester.widget<PhotoSlot>(find.byType(PhotoSlot)).image, testImage);
    });

    testWidgets('frames the face 4:5, 16 below the tabs', (tester) async {
      await pumpInVogue(tester, BeforeAfter(before: testImage, after: after));
      final tabs = tester.getRect(find.byType(DaySwitch));
      final face = tester.getRect(find.byType(PhotoSlot));
      expect(face.top - tabs.bottom, 16);
      expect(face.height, closeTo(350 * 5 / 4, 1e-9));
      expect(
        tester.widget<PhotoSlot>(find.byType(PhotoSlot)).alignment,
        const Alignment(0, -0.4),
      );
    });
  });
}
