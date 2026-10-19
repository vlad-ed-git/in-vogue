import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  group('ProductTile', () {
    Widget tile({
      bool loved = false,
      bool locked = false,
      ValueChanged<bool>? onLove,
      VoidCallback? onTap,
      VoidCallback? onGoPro,
      int colours = 3,
    }) => Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 169,
        child: ProductTile(
          photo: testImage,
          name: 'Oversized Mac Coat',
          colours: List.filled(colours, const Color(0xFFAB9073)),
          loved: loved,
          onLoveChanged: onLove ?? (_) {},
          onTap: onTap ?? () {},
          locked: locked,
          onGoPro: onGoPro,
        ),
      ),
    );

    testWidgets('lays out photo, name row and dots as specified', (
      tester,
    ) async {
      await pumpInVogue(tester, tile());
      final photo = tester.getRect(find.byType(PhotoSlot));
      expect(photo.size, const Size(169, 169 * 5 / 4));
      final name = tester.getRect(find.text('Oversized Mac Coat'));
      expect(name.top - photo.bottom, 8);
      final heart = tester.getRect(find.byType(LoveToggle));
      expect(heart.size, const Size.square(44));
      expect(heart.top, name.top - 12, reason: 'centred on the first line');
      expect(heart.right, photo.right + 12, reason: 'overhangs by 12');
      final dot = tester.getRect(find.byType(Swatch).first);
      expect(dot.size, const Size.square(12));
      expect(find.byType(Swatch), findsNWidgets(3));
    });

    testWidgets('shows at most four dots, then +N', (tester) async {
      await pumpInVogue(tester, tile(colours: 11));
      expect(find.byType(Swatch), findsNWidgets(4));
      expect(find.text('+7'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('11 colours')), findsOneWidget);
    });

    testWidgets('the heart loves; the tile opens', (tester) async {
      bool? loved;
      var opened = 0;
      await pumpInVogue(
        tester,
        tile(onLove: (v) => loved = v, onTap: () => opened++),
      );
      await tester.tap(find.byType(LoveToggle));
      expect(loved, isTrue);
      expect(opened, 0);
      await tester.tap(find.byType(PhotoSlot));
      expect(opened, 1);
    });

    testWidgets('the heart answers taps in its overhang', (tester) async {
      bool? loved;
      await pumpInVogue(tester, tile(onLove: (v) => loved = v));
      final heart = tester.getRect(find.byType(LoveToggle));
      await tester.tapAt(heart.bottomCenter - const Offset(0, 4));
      expect(loved, isTrue);
    });

    testWidgets('locked: faded photo, lock, Go Pro instead of the heart', (
      tester,
    ) async {
      var goPro = 0;
      await pumpInVogue(tester, tile(locked: true, onGoPro: () => goPro++));
      expect(find.byType(LoveToggle), findsNothing);
      expect(tester.widget<PhotoSlot>(find.byType(PhotoSlot)).opacity, 0.45);
      expect(findIcon(InVogueIcons.lock), findsOneWidget);
      await tester.tap(findLink('Go Pro'));
      await tester.tap(find.byType(PhotoSlot));
      expect(goPro, 2);
    });

    testWidgets('long names wrap without clipping at 200% text', (
      tester,
    ) async {
      await pumpInVogue(tester, tile(), textScale: 2);
      expect(tester.takeException(), isNull);
    });
  });

  group('PicksBar', () {
    testWidgets('sits at the bottom of a screen as its bottom bar', (
      tester,
    ) async {
      await pumpInVogue(
        tester,
        Scaffold(
          body: const SizedBox.expand(),
          bottomNavigationBar: PicksBar(
            count: 2,
            action: PicksBarAction.proceed,
            onPressed: () {},
          ),
        ),
        scroll: false,
      );
      final bar = tester.getRect(find.byType(PicksBar));
      final row = math.max(
        InVogueLayout.controlHeight,
        tester.getSize(find.text('Your picks · 2')).height,
      );
      expect(bar.bottom, 844);
      expect(
        bar.height,
        InVogueLayout.strokeHairline + 2 * InVogueSpace.s3 + row,
      );
      expect(
        tester.getSize(find.byType(InVogueButton)).height,
        InVogueLayout.controlHeight,
      );
    });

    testWidgets('count with a Rouge heart, Proceed at 52% width', (
      tester,
    ) async {
      var pressed = 0;
      await pumpInVogue(
        tester,
        Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(viewPadding: const EdgeInsets.only(bottom: 34)),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: PicksBar(
                count: 3,
                action: PicksBarAction.proceed,
                onPressed: () => pressed++,
              ),
            ),
          ),
        ),
        scroll: false,
      );
      expect(find.text('Your picks · 3'), findsOneWidget);
      final heart = tester.widget<Icon>(find.byType(Icon).first);
      expect(heart.icon, InVogueIcons.heartFill);
      expect(heart.color, InVogueColors.signal);
      final bar = tester.getRect(find.byType(PicksBar));
      final button = tester.getRect(find.byType(InVogueButton));
      // The row is as tall as the button, or the label if it wraps.
      final extra =
          math.max(
            InVogueLayout.controlHeight,
            tester.getSize(find.text('Your picks · 3')).height,
          ) -
          InVogueLayout.controlHeight;
      expect(button.width, closeTo(350 * 0.52, 1e-9));
      expect(button.right, bar.right - 20);
      expect(bar.bottom - button.bottom, 12 + 34 + extra / 2);
      expect(button.top - bar.top, 12 + 1 + extra / 2);
      await tester.tap(find.text('Proceed'));
      expect(pressed, 1);
    });

    testWidgets('zero picks is fine: an ink heart and Done', (tester) async {
      await pumpInVogue(
        tester,
        PicksBar(count: 0, action: PicksBarAction.done, onPressed: () {}),
      );
      expect(find.text('Your picks · 0'), findsOneWidget);
      final heart = tester.widget<Icon>(find.byType(Icon).first);
      expect(heart.icon, InVogueIcons.heart);
      expect(heart.color, InVogueColors.ink);
      expect(find.text('Done'), findsOneWidget);
      expect(findIcon(InVogueIcons.check), findsOneWidget);
    });
  });

  group('ShopItem', () {
    testWidgets('two halves: photo and details with Buy pinned below', (
      tester,
    ) async {
      var bought = 0;
      await pumpInVogue(
        tester,
        ShopItem(
          photo: testImage,
          name: 'The Luxe Rib Turtleneck',
          colourName: 'White',
          colour: const Color(0xFFD8D7DE),
          material: '75% Supima cotton, 25% elastane',
          brand: 'Everlane',
          onBuy: () => bought++,
        ),
        size: const Size(800, 844),
      );
      final photo = tester.getRect(find.byType(PhotoSlot));
      final button = tester.getRect(find.byType(InVogueButton));
      expect(photo.width, (760 - 12) / 2);
      expect(button.left - photo.right, 12);
      expect(button.bottom, photo.bottom);
      expect(button.height, 44);
      expect(find.text('75% Supima cotton, 25% elastane'), findsOneWidget);
      expect(find.text('Buy at Everlane'), findsOneWidget);
      expect(findIcon(InVogueIcons.arrowUpRight), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          'The Luxe Rib Turtleneck in White, catalogue photo',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('Buy at Everlane'));
      expect(bought, 1);
    });

    testWidgets('unavailable: says so and has no button', (tester) async {
      await pumpInVogue(
        tester,
        const ShopItem(
          photo: null,
          name: 'Tailored Drape Balloon Pant',
          colourName: 'Navy',
          colour: Color(0xFF262B38),
          brand: 'Everlane',
          onBuy: null,
        ),
      );
      expect(find.text('No longer available at Everlane'), findsOneWidget);
      expect(find.byType(InVogueButton), findsNothing);
    });

    testWidgets('a long name grows the row at 200% text', (tester) async {
      await pumpInVogue(
        tester,
        ShopItem(
          photo: testImage,
          name: 'Tailored Drape Balloon Pant in Washed Cotton Twill',
          colourName: 'Navy',
          colour: const Color(0xFF262B38),
          material: 'Cotton',
          brand: 'Everlane',
          onBuy: () {},
        ),
        textScale: 2,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
