import 'dart:math' as math;

import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/services/colour_space.dart';

/// In Vogue's own colour analysis: turns a face's sampled colours into one
/// of the twelve seasons by undertone, depth and contrast, each with a
/// hardcoded palette. YouCam samples the colours; the season is ours, a
/// suggestion, never YouCam's claim.
///
/// - Undertone: the skin's CIELAB hue angle; between the two thresholds it
///   is neutral, and the hair says which way it leans.
/// - Depth: the mean lightness of skin and hair; deep skin by ITA° (Chardon
///   1991) is always deep.
/// - Contrast: the lightness gap between the skin and the darker of the
///   brows and hair.
abstract final class SeasonRules {
  /// Colours used when there are none to trust.
  static const neutralColours = FaceColours(
    skin: '#C69C82',
    eyebrow: '#4A3628',
    lip: '#B5726E',
    hair: '#4A3628',
    clear: false,
  );

  /// Skin hue angles, in degrees, from which the undertone is warm, and up
  /// to which it is cool.
  static const warmFrom = 60.0;
  static const coolTo = 52.0;

  /// The hue angle a neutral skin leans warm from, when the hair says
  /// nothing.
  static const neutralLean = 56.0;

  /// Hair chroma from which golden or copper hair warms a neutral skin, and
  /// below which ash or black hair cools it.
  static const warmHairChroma = 12.0;
  static const coolHairChroma = 6.0;

  /// Mean lightness of skin and hair from which colouring is light, and
  /// below which it is deep.
  static const lightFrom = 62.0;
  static const deepBelow = 36.0;

  /// ITA° below which skin is deep, whatever the hair.
  static const deepSkinBelow = 12.0;

  /// Lightness gaps, in CIELAB L*, where medium and high contrast begin.
  static const mediumContrastFrom = 25.0;
  static const highContrastFrom = 45.0;

  /// Mean lightness from which warm, medium colouring is spring.
  static const springFrom = 58.0;

  /// The reading of [colours]; unreadable colours read as [neutralColours].
  static ColourReading readingOf(FaceColours colours) {
    final skin = _lab(colours.skin);
    final hair = _lab(colours.hair);
    final brow = _lab(colours.eyebrow);
    if (skin == null || hair == null || brow == null) {
      return readingOf(neutralColours);
    }
    final mean = (skin.l + hair.l) / 2;
    final depth = _itaOf(skin) < deepSkinBelow || mean < deepBelow
        ? Depth.deep
        : mean >= lightFrom
        ? Depth.light
        : Depth.medium;
    final gap = skin.l - math.min(brow.l, hair.l);
    final contrast = gap >= highContrastFrom
        ? Contrast.high
        : gap >= mediumContrastFrom
        ? Contrast.medium
        : Contrast.low;
    final hue = _hueOf(skin);
    final undertone = hue >= warmFrom
        ? Undertone.warm
        : hue <= coolTo
        ? Undertone.cool
        : Undertone.neutral;
    final warm = switch (undertone) {
      Undertone.warm => true,
      Undertone.cool => false,
      Undertone.neutral => _leansWarm(hue, hair),
    };
    final season = switch ((depth, contrast)) {
      (Depth.deep, _) =>
        warm ? ColourSeason.darkAutumn : ColourSeason.darkWinter,
      (_, Contrast.high) =>
        warm
            ? ColourSeason.brightSpring
            : depth == Depth.light
            ? ColourSeason.brightWinter
            : ColourSeason.trueWinter,
      (Depth.light, _) =>
        warm ? ColourSeason.lightSpring : ColourSeason.lightSummer,
      _ when contrast == Contrast.low || undertone == Undertone.neutral =>
        warm ? ColourSeason.softAutumn : ColourSeason.softSummer,
      _ =>
        warm
            ? (mean >= springFrom
                  ? ColourSeason.trueSpring
                  : ColourSeason.trueAutumn)
            : ColourSeason.trueSummer,
    };
    return ColourReading(
      season: season,
      undertone: undertone,
      depth: depth,
      contrast: contrast,
      palette: palettes[season]!,
      clear: colours.clear,
    );
  }

  /// Golden or copper hair warms a neutral skin, ash or black hair cools
  /// it; otherwise the skin's own hue decides.
  static bool _leansWarm(
    double skinHue,
    ({double l, double a, double b}) hair,
  ) {
    final chroma = math.sqrt(hair.a * hair.a + hair.b * hair.b);
    final hue = _hueOf(hair);
    if (chroma >= warmHairChroma && hue >= 40 && hue <= 90) return true;
    if (chroma < coolHairChroma) return false;
    return skinHue >= neutralLean;
  }

  /// Each season's colours: twelve that suit, six neutrals, four to go
  /// easy on.
  static const palettes = {
    ColourSeason.lightSpring: ColourPalette(
      suits: [
        0xFFF9C6A8, 0xFFF7A08C, 0xFFFBD98C, 0xFFF5E6A3, 0xFFB8DDB0, //
        0xFF8ED1C6, 0xFF9CC9E8, 0xFFC7B8E5, 0xFFF4A9B8, 0xFFE8C39E,
        0xFFF2B07B, 0xFFA9D8A0,
      ],
      neutrals: [
        0xFFFFF8E7, 0xFFF1E3CC, 0xFFD9C2A3, 0xFFB9A68C, 0xFF8D7B68, //
        0xFF6B7A8F,
      ],
      avoid: [0xFF000000, 0xFF6B2D5C, 0xFF4A4A4A, 0xFF8B0000],
    ),
    ColourSeason.trueSpring: ColourPalette(
      suits: [
        0xFFF04E31, 0xFFFF7F50, 0xFFFFC72C, 0xFFFFB347, 0xFF7AC143, //
        0xFF2EB7A5, 0xFF3A8FD9, 0xFFF45B94, 0xFFE8A33D, 0xFFC1D82F,
        0xFFF7B5A0, 0xFF00A693,
      ],
      neutrals: [
        0xFFFFF5DC, 0xFFE9D4B0, 0xFFC19A6B, 0xFF8B6B4A, 0xFF7E7A6E, //
        0xFF1F3A5F,
      ],
      avoid: [0xFF000000, 0xFF708090, 0xFF4B0082, 0xFF800020],
    ),
    ColourSeason.brightSpring: ColourPalette(
      suits: [
        0xFFFF3B30, 0xFFFF6F3C, 0xFFFFD60A, 0xFF00C2A8, 0xFF0096FF, //
        0xFFB455E0, 0xFFFF4F9A, 0xFF34C759, 0xFFFF9F1C, 0xFF00B4D8,
        0xFFFF85A1, 0xFF2DD4BF,
      ],
      neutrals: [
        0xFFFFFAF0, 0xFFE8DCCA, 0xFFC8A97E, 0xFFA67B5B, 0xFF6E6E6E, //
        0xFF1B2A4A,
      ],
      avoid: [0xFFA89F91, 0xFF9DAE9D, 0xFFC8A2A8, 0xFF6B5B4E],
    ),
    ColourSeason.lightSummer: ColourPalette(
      suits: [
        0xFFAFCBEA, 0xFFC3B1E1, 0xFFF4B6C2, 0xFFB5E2D6, 0xFFE6A8C2, //
        0xFF9FB7D9, 0xFFF7C9C4, 0xFFA8D5BA, 0xFFD3C4E3, 0xFF8FB8DE,
        0xFFE8B4D0, 0xFFB7C9E2,
      ],
      neutrals: [
        0xFFFAF8F5, 0xFFE5E4E2, 0xFFC9C6C1, 0xFFA3A6AD, 0xFF8C8A93, //
        0xFF4E5D73,
      ],
      avoid: [0xFFFF4500, 0xFF000000, 0xFF8B4513, 0xFFFFD700],
    ),
    ColourSeason.trueSummer: ColourPalette(
      suits: [
        0xFF5B7DB1, 0xFFC2185B, 0xFF4F9A94, 0xFF8E7CC3, 0xFFD8738F, //
        0xFF6A9FB5, 0xFF9B6B9E, 0xFFE57399, 0xFF5E8C6A, 0xFF3E5C8A,
        0xFFB5446E, 0xFF7FA7C9,
      ],
      neutrals: [
        0xFFF5F5F5, 0xFFD6D6D6, 0xFF9E9E9E, 0xFF6E7B8B, 0xFF46505A, //
        0xFF2C3E50,
      ],
      avoid: [0xFFFF8C00, 0xFFDAA520, 0xFF8B5A2B, 0xFF000000],
    ),
    ColourSeason.softSummer: ColourPalette(
      suits: [
        0xFFC9A9A6, 0xFF9CAF88, 0xFF7D8FA8, 0xFFA391A8, 0xFFB57F8C, //
        0xFF6E8B87, 0xFF8C9DB5, 0xFFBBA6A0, 0xFF7F8C6E, 0xFFA5B8C7,
        0xFF946B7D, 0xFFC4B7A6,
      ],
      neutrals: [
        0xFFF0EDE8, 0xFFCFC8C0, 0xFFA39E98, 0xFF7A7672, 0xFF5C6670, //
        0xFF3F4A57,
      ],
      avoid: [0xFFFF0000, 0xFFFFA500, 0xFF000000, 0xFFFFFF00],
    ),
    ColourSeason.softAutumn: ColourPalette(
      suits: [
        0xFFB39B72, 0xFF8A9A5B, 0xFFC9A27E, 0xFFA67B5B, 0xFFC48A6A, //
        0xFF7E8C6A, 0xFFD2B48C, 0xFF9C7C5C, 0xFF6F8C7E, 0xFFB5838D,
        0xFFC2B280, 0xFF8F6F5A,
      ],
      neutrals: [
        0xFFF3E9DC, 0xFFD8C8B0, 0xFFB8A68E, 0xFF8E7F6E, 0xFF6B5E52, //
        0xFF4A5240,
      ],
      avoid: [0xFF000000, 0xFFFFFFFF, 0xFFFF1493, 0xFF0047AB],
    ),
    ColourSeason.trueAutumn: ColourPalette(
      suits: [
        0xFFB7410E, 0xFF708238, 0xFFE1AD01, 0xFF00827F, 0xFFC46210, //
        0xFF8B4513, 0xFFCC7722, 0xFF556B2F, 0xFFA0522D, 0xFFDAA520,
        0xFF9E3B26, 0xFF4F7942,
      ],
      neutrals: [
        0xFFFFF4E0, 0xFFC19A6B, 0xFF8B5A2B, 0xFF654321, 0xFF5D5346, //
        0xFF3B3C36,
      ],
      avoid: [0xFFFF69B4, 0xFFE0B0FF, 0xFF87CEEB, 0xFFC0C0C0],
    ),
    ColourSeason.darkAutumn: ColourPalette(
      suits: [
        0xFF4E2A1E, 0xFF614051, 0xFF2E5E3F, 0xFFCC5500, 0xFF8B3A3A, //
        0xFF996515, 0xFF00544F, 0xFF7B3F00, 0xFF6B4423, 0xFF9C6B30,
        0xFF3D5229, 0xFF8E3B2F,
      ],
      neutrals: [
        0xFFF5EBDC, 0xFFA67B5B, 0xFF5C4033, 0xFF3B2F2F, 0xFF4A4A3A, //
        0xFF1C2A39,
      ],
      avoid: [0xFFFFB6C1, 0xFFADD8E6, 0xFFE6E6FA, 0xFFFFFFFF],
    ),
    ColourSeason.darkWinter: ColourPalette(
      suits: [
        0xFF800020, 0xFF01796F, 0xFF1B2A49, 0xFF5B2C6F, 0xFFB0003A, //
        0xFF004B49, 0xFF343A56, 0xFF8B0000, 0xFF3D0C45, 0xFF0F5257,
        0xFF7A1F3D, 0xFF1E5945,
      ],
      neutrals: [
        0xFFF8F8FF, 0xFFBEBEBE, 0xFF5A5A64, 0xFF2B2B2B, 0xFF000000, //
        0xFF1C2541,
      ],
      avoid: [0xFFF5DEB3, 0xFFFFDAB9, 0xFFF0E68C, 0xFFDEB887],
    ),
    ColourSeason.trueWinter: ColourPalette(
      suits: [
        0xFFD2042D, 0xFF4169E1, 0xFF009B77, 0xFFC71585, 0xFF00A3AD, //
        0xFF6A0DAD, 0xFF0047AB, 0xFFE30B5C, 0xFF50C878, 0xFF1560BD,
        0xFFFF1493, 0xFF8A2BE2,
      ],
      neutrals: [
        0xFFFFFFFF, 0xFFE5E5E5, 0xFF8C8C8C, 0xFF36454F, 0xFF000000, //
        0xFF000080,
      ],
      avoid: [0xFFFFA07A, 0xFFCD853F, 0xFFF4A460, 0xFF808000],
    ),
    ColourSeason.brightWinter: ColourPalette(
      suits: [
        0xFFFF1493, 0xFF0047FF, 0xFF00CED1, 0xFFFF0033, 0xFF7F00FF, //
        0xFF00A86B, 0xFFFFF44F, 0xFFE0115F, 0xFF1E90FF, 0xFF9400D3,
        0xFF00C87C, 0xFFFF66CC,
      ],
      neutrals: [
        0xFFFFFFFF, 0xFFF0F0F0, 0xFFA9A9A9, 0xFF333333, 0xFF000000, //
        0xFF191970,
      ],
      avoid: [0xFFC3B091, 0xFFB5A642, 0xFFA0785A, 0xFF9DAE9D],
    ),
  };

  /// The individual typology angle of a CIELAB colour, in degrees.
  static double _itaOf(Lab lab) =>
      math.atan2(lab.l - 50, lab.b) * 180 / math.pi;

  /// The CIELAB hue angle, in degrees.
  static double _hueOf(Lab lab) => math.atan2(lab.b, lab.a) * 180 / math.pi;

  /// CIELAB of `#RRGGBB`; null when [hex] is not one.
  static Lab? _lab(String hex) => switch (ColourSpace.argbOf(hex)) {
    final argb? => ColourSpace.labOf(argb),
    null => null,
  };
}
