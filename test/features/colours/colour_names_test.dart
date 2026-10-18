import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/colours/domain/services/colour_names.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

void main() {
  test('a named colour is called by its own name', () {
    for (final MapEntry(key: name, value: argb) in ColourNames.named.entries) {
      expect(ColourNames.nameOf(argb), name, reason: name);
    }
  });

  test('a colour takes the nearest name', () {
    expect(ColourNames.nameOf(0xFF1B2A49), 'navy');
    expect(ColourNames.nameOf(0xFF7A1F3D), 'wine');
    expect(ColourNames.nameOf(0xFFB7410E), 'rust');
    expect(ColourNames.nameOf(0xFFF9C6A8), 'peach');
    expect(ColourNames.nameOf(0xFF9CAF88), 'sage');
  });

  test('each language names a colour in its own words', () {
    expect(
      lookupAppLocalizations(const Locale('en')).colourName('navy'),
      'Navy',
    );
    expect(
      lookupAppLocalizations(const Locale('es')).colourName('navy'),
      'Azul marino',
    );
    expect(
      lookupAppLocalizations(const Locale('zh')).colourName('navy'),
      '藏青色',
    );
  });

  test('every colour in every palette has a name in all three languages', () {
    final colours = {
      for (final palette in SeasonRules.palettes.values) ...[
        ...palette.suits,
        ...palette.neutrals,
        ...palette.avoid,
      ],
    };
    for (final language in ['en', 'es', 'zh']) {
      final l10n = lookupAppLocalizations(Locale(language));
      final fallback = l10n.colourName('none');
      for (final colour in colours) {
        expect(
          l10n.colourName(ColourNames.nameOf(colour)),
          isNot(fallback),
          reason: '$language ${colour.toRadixString(16)}',
        );
      }
      for (final name in ColourNames.named.keys) {
        expect(
          l10n.colourName(name),
          isNot(fallback),
          reason: '$language $name',
        );
      }
    }
  });
}
