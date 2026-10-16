import 'dart:math' as math;

import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';

/// Turns a face's sampled colours into a skin profile, as the knowledge
/// base's skin.v1.json says: the shade group from the skin's ITA°
/// (Chardon 1991), the contrast from the lightness gap between the skin and
/// the darker of the brows and hair, and the concealer and nude lip shifted
/// from the skin and lips in OKLab. Never undertone.
abstract final class SkinRules {
  /// Colours used when there are none to trust.
  static const neutralColours = FaceColours(
    skin: '#C69C82',
    eyebrow: '#4A3628',
    lip: '#B5726E',
    hair: '#4A3628',
    clear: false,
  );

  /// The profile for a missing or unclear analysis: medium shades and
  /// contrast in neutral colours.
  static final neutral = _profile(
    neutralColours,
    shadeGroup: ShadeGroup.medium,
    contrast: SkinContrast.medium,
    matched: false,
  )!;

  /// Lowest ITA° of the light and medium groups.
  static const lightFrom = 41.0;
  static const mediumFrom = 10.0;

  /// ITA° this close above a group's lowest counts as the deeper group: a
  /// pale wash on deep skin reads as ashy. The app's own margin.
  static const boundaryMargin = 2.0;

  /// Lightness gaps, in CIELAB L*, where medium and high contrast begin.
  static const mediumContrastFrom = 25.0;
  static const highContrastFrom = 45.0;

  /// OKLab lightness added for the concealer, taken off for the nude lip.
  static const concealerLift = 0.03;
  static const nudeLipDepth = 0.03;

  /// Chroma kept in the nude lip.
  static const nudeLipChroma = 0.9;

  /// The profile of [colours]; [neutral] when they are missing, unclear or
  /// unreadable.
  static SkinProfile profileOf(FaceColours? colours) {
    if (colours == null || !colours.clear) return neutral;
    final skin = _lab(colours.skin);
    final brow = _lab(colours.eyebrow);
    final hair = _lab(colours.hair);
    if (skin == null || brow == null || hair == null) return neutral;
    return _profile(
          colours,
          shadeGroup: shadeGroupOf(itaOf(skin)),
          contrast: contrastOf(skin.l - math.min(brow.l, hair.l)),
          matched: true,
        ) ??
        neutral;
  }

  /// The individual typology angle of a CIELAB colour, in degrees.
  static double itaOf(({double l, double a, double b}) lab) =>
      math.atan2(lab.l - 50, lab.b) * 180 / math.pi;

  static ShadeGroup shadeGroupOf(double ita) {
    if (ita >= lightFrom + boundaryMargin) return ShadeGroup.light;
    if (ita >= mediumFrom + boundaryMargin) return ShadeGroup.medium;
    return ShadeGroup.deep;
  }

  /// The contrast of a lightness gap in CIELAB L*.
  static SkinContrast contrastOf(double gap) {
    if (gap >= highContrastFrom) return SkinContrast.high;
    if (gap >= mediumContrastFrom) return SkinContrast.medium;
    return SkinContrast.low;
  }

  static SkinProfile? _profile(
    FaceColours colours, {
    required ShadeGroup shadeGroup,
    required SkinContrast contrast,
    required bool matched,
  }) {
    final skin = _rgb(colours.skin);
    final brow = _rgb(colours.eyebrow);
    final lip = _rgb(colours.lip);
    if (skin == null || brow == null || lip == null) return null;
    final skinLab = _okLab(skin);
    final lipLab = _okLab(lip);
    return SkinProfile(
      shadeGroup: shadeGroup,
      contrast: contrast,
      foundation: _hex(skin),
      concealer: _hex(
        _fromOkLab((l: skinLab.l + concealerLift, a: skinLab.a, b: skinLab.b)),
      ),
      brow: _hex(brow),
      nudeLip: _hex(
        _fromOkLab((
          l: lipLab.l - nudeLipDepth,
          a: lipLab.a * nudeLipChroma,
          b: lipLab.b * nudeLipChroma,
        )),
      ),
      matched: matched,
    );
  }

  /// "#RRGGBB" as sRGB channels from 0 to 1; null when it is not one.
  static ({double r, double g, double b})? _rgb(String hex) {
    final match = RegExp(
      r'^#([0-9a-fA-F]{2})([0-9a-fA-F]{2})([0-9a-fA-F]{2})$',
    ).firstMatch(hex);
    if (match == null) return null;
    double channel(int group) =>
        int.parse(match.group(group)!, radix: 16) / 255;
    return (r: channel(1), g: channel(2), b: channel(3));
  }

  static String _hex(({double r, double g, double b}) rgb) {
    String channel(double value) =>
        (value.clamp(0, 1) * 255).round().toRadixString(16).padLeft(2, '0');
    return '#${channel(rgb.r)}${channel(rgb.g)}${channel(rgb.b)}'.toUpperCase();
  }

  static double _linear(double value) => value <= 0.04045
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  static double _gamma(double value) => value <= 0.0031308
      ? value * 12.92
      : 1.055 * math.pow(value, 1 / 2.4) - 0.055;

  static double _cbrt(double value) => value < 0
      ? -math.pow(-value, 1 / 3).toDouble()
      : math.pow(value, 1 / 3).toDouble();

  /// CIELAB under D65; null when [hex] is not a colour.
  static ({double l, double a, double b})? _lab(String hex) {
    final rgb = _rgb(hex);
    if (rgb == null) return null;
    final r = _linear(rgb.r);
    final g = _linear(rgb.g);
    final b = _linear(rgb.b);
    final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
    final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
    final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;
    double f(double t) =>
        t > 216 / 24389 ? _cbrt(t) : t * 24389 / 27 / 116 + 16 / 116;
    return (l: 116 * f(y) - 16, a: 500 * (f(x) - f(y)), b: 200 * (f(y) - f(z)));
  }

  static ({double l, double a, double b}) _okLab(
    ({double r, double g, double b}) rgb,
  ) {
    final r = _linear(rgb.r);
    final g = _linear(rgb.g);
    final b = _linear(rgb.b);
    final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return (
      l: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    );
  }

  static ({double r, double g, double b}) _fromOkLab(
    ({double l, double a, double b}) lab,
  ) {
    final l = math.pow(lab.l + 0.3963377774 * lab.a + 0.2158037573 * lab.b, 3);
    final m = math.pow(lab.l - 0.1055613458 * lab.a - 0.0638541728 * lab.b, 3);
    final s = math.pow(lab.l - 0.0894841775 * lab.a - 1.2914855480 * lab.b, 3);
    return (
      r: _gamma(4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s),
      g: _gamma(-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s),
      b: _gamma(-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s),
    );
  }
}
