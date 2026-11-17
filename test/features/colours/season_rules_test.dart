import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/services/season_rules.dart';

FaceColours _face(String skin, String hair, String brow, {bool clear = true}) =>
    FaceColours(
      skin: skin,
      eyebrow: brow,
      lip: '#B5726E',
      hair: hair,
      clear: clear,
    );

/// The skin-tone analysis's seven hair colours.
const _youCamHairs = [
  '#000000',
  '#42280E',
  '#722626',
  '#B56637',
  '#FAF0BE',
  '#808080',
  '#A0A0A0',
];

/// Brows from dark to light: L* 18 to 58, brownish grey.
const _referenceBrows = ['#332A25', '#4A403A', '#625851', '#7B7069', '#948982'];

/// Skins in each of Chardon's six ITA° classes, from dark to very light,
/// at hue angles and chromas plausible for skin.
Iterable<String> _referenceSkins() sync* {
  const classes = [
    (-50, -30),
    (-30, 10),
    (10, 28),
    (28, 41),
    (41, 55),
    (55, 70),
  ];
  for (final (low, high) in classes) {
    for (var step = 0; step < 3; step++) {
      final ita = (low + (high - low) * (step + 0.5) / 3) * math.pi / 180;
      for (final hue in const [46, 50, 54, 58, 62, 66]) {
        for (final chroma in const [12, 18, 24, 30]) {
          final a = chroma * math.cos(hue * math.pi / 180);
          final b = chroma * math.sin(hue * math.pi / 180);
          final l = 50 + b * math.tan(ita);
          if (l >= 20 && l <= 92) yield _hexOfLab(l, a, b);
        }
      }
    }
  }
}

/// `#RRGGBB` of a CIELAB colour under D65, clipped to sRGB.
String _hexOfLab(double l, double a, double b) {
  double inverse(double t) =>
      t * t * t > 216 / 24389 ? t * t * t : (116 * t - 16) / (24389 / 27);
  final fy = (l + 16) / 116;
  final x = inverse(fy + a / 500) * 0.95047;
  final y = inverse(fy);
  final z = inverse(fy - b / 200) * 1.08883;
  String channel(double linear) {
    final c = linear.clamp(0.0, 1.0);
    final value = c <= 0.0031308
        ? 12.92 * c
        : 1.055 * math.pow(c, 1 / 2.4) - 0.055;
    return (value * 255).round().toRadixString(16).padLeft(2, '0');
  }

  return '#${channel(3.2404542 * x - 1.5371385 * y - 0.4985314 * z)}'
          '${channel(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z)}'
          '${channel(0.0556434 * x - 0.2040259 * y + 1.0572252 * z)}'
      .toUpperCase();
}

void main() {
  group('the season of a face', () {
    final cases = {
      'golden blonde, peachy fair': (
        _face('#F3D3B5', '#C9A26B', '#A07850'),
        ColourSeason.lightSpring,
      ),
      'light warm skin, red hair': (
        _face('#F1CDB0', '#B5562A', '#A0603A'),
        ColourSeason.lightSpring,
      ),
      'medium warm skin, auburn hair': (
        _face('#D7A47E', '#8A4B2A', '#7A4A30'),
        ColourSeason.trueAutumn,
      ),
      'deep warm skin': (
        _face('#8D5524', '#2B1B10', '#2B1B10'),
        ColourSeason.darkAutumn,
      ),
      'olive skin, dark brown hair': (
        _face('#C08A66', '#3B2A20', '#3B2A20'),
        ColourSeason.softAutumn,
      ),
      'rosy fair skin, ash light brown hair': (
        _face('#E3C2B9', '#A89585', '#9A8878'),
        ColourSeason.lightSummer,
      ),
      'cool medium skin, ash brown hair': (
        _face('#C7A096', '#6E625C', '#625852'),
        ColourSeason.trueSummer,
      ),
      'pink fair skin, black hair': (
        _face('#EBC9C3', '#1A1A1A', '#222222'),
        ColourSeason.trueWinter,
      ),
      'deep cool skin': (
        _face('#6B4A44', '#141414', '#141414'),
        ColourSeason.darkWinter,
      ),
    };
    for (final MapEntry(key: name, value: (face, season)) in cases.entries) {
      test(name, () => expect(SeasonRules.readingOf(face).season, season));
    }
  });

  test('keeps the colours it was read from', () {
    final face = _face('#EBC9C3', '#1A1A1A', '#222222');
    expect(SeasonRules.readingOf(face).colours, face);
  });

  test('says why: undertone, depth and contrast', () {
    final reading = SeasonRules.readingOf(
      _face('#EBC9C3', '#1A1A1A', '#222222'),
    );
    expect(reading.undertone, Undertone.cool);
    expect(reading.depth, Depth.medium);
    expect(reading.contrast, Contrast.high);
    expect(reading.palette, SeasonRules.palettes[ColourSeason.trueWinter]);
  });

  test('a neutral undertone leans on the hair: golden hair warms it', () {
    final reading = SeasonRules.readingOf(
      _face('#C9A18A', '#6B5444', '#5E4A3C'),
    );
    expect(reading.undertone, Undertone.neutral);
    expect(reading.season, ColourSeason.softAutumn);
  });

  test('black hair alone makes a medium face neither deep nor high '
      'contrast', () {
    final reading = SeasonRules.readingOf(
      _face('#C99A78', '#000000', '#4A3628'),
    );
    expect(reading.depth, Depth.medium);
    expect(reading.contrast, Contrast.medium);
    expect(reading.season, ColourSeason.trueAutumn);
  });

  test('spreads plausible faces over every season, none taking more than '
      'a fifth', () {
    final counts = <ColourSeason, int>{};
    var faces = 0;
    for (final skin in _referenceSkins()) {
      for (final brow in _referenceBrows) {
        for (final hair in _youCamHairs) {
          final season = SeasonRules.readingOf(_face(skin, hair, brow)).season;
          counts[season] = (counts[season] ?? 0) + 1;
          faces++;
        }
      }
    }
    expect(counts.keys, unorderedEquals(ColourSeason.values));
    for (final MapEntry(key: season, value: count) in counts.entries) {
      expect(count / faces, lessThanOrEqualTo(0.2), reason: '$season');
    }
  });

  test('keeps whether the photo was clear enough to trust', () {
    expect(SeasonRules.readingOf(SeasonRules.neutralColours).clear, isFalse);
    expect(
      SeasonRules.readingOf(_face('#F3D3B5', '#C9A26B', '#A07850')).clear,
      isTrue,
    );
  });

  test('unreadable colours read as the neutral colours', () {
    expect(
      SeasonRules.readingOf(_face('tan', '#C9A26B', '#A07850')).season,
      SeasonRules.readingOf(SeasonRules.neutralColours).season,
    );
  });

  test('every season has its palette: twelve colours that suit, six '
      'neutrals and four to go easy on, all opaque and different', () {
    expect(SeasonRules.palettes.keys, unorderedEquals(ColourSeason.values));
    for (final MapEntry(key: season, value: palette)
        in SeasonRules.palettes.entries) {
      expect(palette.suits, hasLength(12), reason: '$season');
      expect(palette.neutrals, hasLength(6), reason: '$season');
      expect(palette.avoid, hasLength(4), reason: '$season');
      final all = [...palette.suits, ...palette.neutrals, ...palette.avoid];
      expect(all.toSet(), hasLength(all.length), reason: '$season');
      expect(all.every((colour) => colour >> 24 == 0xFF), isTrue);
    }
  });
}
