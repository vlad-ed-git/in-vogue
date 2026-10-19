import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph_paths.dart';
import 'package:in_vogue/core/presentation/presentation.dart';

import '../../../helpers/pump_in_vogue.dart';

void main() {
  const icons = [
    InVogueIcons.heart,
    InVogueIcons.arrowRight,
    InVogueIcons.arrowUpRight,
    InVogueIcons.caretLeft,
    InVogueIcons.check,
    InVogueIcons.image,
    InVogueIcons.lock,
    InVogueIcons.mapPin,
    InVogueIcons.retry,
    InVogueIcons.offline,
    InVogueIcons.warning,
    InVogueIcons.handTap,
    InVogueIcons.plus,
    InVogueIcons.squaresFour,
    InVogueIcons.signOut,
    InVogueIcons.trash,
    InVogueIcons.appleLogo,
    InVogueIcons.googleLogo,
  ];

  test('interface icons are Phosphor Regular; the loved heart is Fill', () {
    for (final icon in icons) {
      expect(icon.fontFamily, 'PhosphorRegular');
      expect(icon.fontPackage, 'phosphoricons_flutter');
    }
    expect(InVogueIcons.heartFill.fontFamily, 'PhosphorFill');
    expect(InVogueIcons.heartFill.codePoint, InVogueIcons.heart.codePoint);
  });

  testWidgets('icons take the theme size and ink', (tester) async {
    await pumpInVogue(tester, const Icon(InVogueIcons.check));
    expect(
      tester.getSize(find.byIcon(InVogueIcons.check)),
      const Size.square(24),
    );
    final text = tester.widget<RichText>(
      find.descendant(
        of: find.byIcon(InVogueIcons.check),
        matching: find.byType(RichText),
      ),
    );
    expect(text.text.style!.color, InVogueColors.ink);
  });

  test('SVG path parsing is cached', () {
    final path = SvgPath.parse(weatherCloudBodyPath);
    expect(identical(path, SvgPath.parse(weatherCloudBodyPath)), isTrue);
    expect(path.getBounds().isEmpty, isFalse);
  });
}
