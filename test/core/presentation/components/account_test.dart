import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

/// A photo whose file is gone.
class _BrokenImage extends ImageProvider<_BrokenImage> {
  const _BrokenImage();

  @override
  Future<_BrokenImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(_BrokenImage key, ImageDecoderCallback _) =>
      OneFrameImageStreamCompleter(
        Future<ImageInfo>.error(const FileSystemException('gone')),
      );
}

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
      expect(find.text('M'), findsNothing, reason: 'the photo wins');
    });

    testWidgets('without a face photo, the profile row shows the initial in '
        'white on Rouge, centred', (tester) async {
      await pumpInVogue(
        tester,
        const SettingsRow.profile(title: 'maya', avatar: null),
      );
      expect(find.byType(PhotoSlot), findsNothing);
      final square = find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == InVogueColors.signal,
      );
      final box = tester.getRect(square);
      expect(box.size, const Size.square(56));
      final letter = find.descendant(of: square, matching: find.text('M'));
      expect(tester.widget<Text>(letter).style!.color, InVogueColors.onSignal);
      expect(tester.getCenter(letter), box.center);
      expect(tester.getTopLeft(find.text('maya')).dx - box.right, 12);
    });

    testWidgets('the initial is the first character, so Chinese names and '
        'emoji work', (tester) async {
      for (final (name, initial) in [
        ('王芳', '王'),
        ('👩🏽‍💻 Kim', '👩🏽‍💻'),
        ('  élodie', 'É'),
      ]) {
        await pumpInVogue(
          tester,
          SettingsRow.profile(title: name, avatar: null),
        );
        expect(find.text(initial), findsOneWidget, reason: name);
      }
    });

    testWidgets('a face photo that cannot be drawn shows the initial, not '
        'an empty slot', (tester) async {
      await pumpInVogue(
        tester,
        const SettingsRow.profile(title: 'maya', avatar: _BrokenImage()),
      );
      await tester.pump();
      final square = find.byWidgetPredicate(
        (widget) =>
            widget is ColoredBox && widget.color == InVogueColors.signal,
      );
      expect(
        find.descendant(of: square, matching: find.text('M')),
        findsOneWidget,
      );
    });

    testWidgets('a blank name keeps the empty Rose slot', (tester) async {
      await pumpInVogue(
        tester,
        const SettingsRow.profile(title: ' ', avatar: null),
      );
      final slot = find.descendant(
        of: find.byType(PhotoSlot),
        matching: find.byType(ColoredBox),
      );
      expect(fillOf(tester, slot), InVogueColors.accent);
    });

    testWidgets('the initial keeps its size at 200% and screen readers skip '
        'it', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpInVogue(
        tester,
        const SettingsRow.profile(title: 'Maya', avatar: null),
        textScale: 2,
      );
      expect(tester.getSize(find.text('M')).height, 38);
      expect(find.bySemanticsLabel('M'), findsNothing);
      expect(find.bySemanticsLabel('Maya'), findsOneWidget);
      semantics.dispose();
    });

    testWidgets('log out and delete are whole-row Rouge commands', (
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
      for (final icon in [InVogueIcons.signOut, InVogueIcons.trash]) {
        expect(tester.widget<Icon>(findIcon(icon)).color, InVogueColors.signal);
      }
      for (final title in ['Log out', 'Delete account']) {
        expect(
          tester.widget<Text>(find.text(title)).style!.color,
          InVogueColors.signal,
        );
      }
      await tester.tap(find.byType(SettingsRow).first);
      await tester.tapAt(
        tester.getCenter(find.byType(SettingsRow).last) + const Offset(120, 0),
      );
      expect(taps, ['out', 'delete']);
    });
  });
}
