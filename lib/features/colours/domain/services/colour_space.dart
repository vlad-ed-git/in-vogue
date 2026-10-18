import 'dart:math' as math;

/// A colour in CIELAB under D65.
typedef Lab = ({double l, double a, double b});

/// Colour maths shared by the season rules and the colour names.
abstract final class ColourSpace {
  /// CIELAB of an sRGB `0xAARRGGBB` colour.
  static Lab labOf(int argb) {
    double channel(int shift) => _linear(((argb >> shift) & 0xFF) / 255);
    final r = channel(16);
    final g = channel(8);
    final b = channel(0);
    final x = (0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / 0.95047;
    final y = 0.2126729 * r + 0.7151522 * g + 0.0721750 * b;
    final z = (0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / 1.08883;
    final fx = _f(x);
    final fy = _f(y);
    final fz = _f(z);
    return (l: 116 * fy - 16, a: 500 * (fx - fy), b: 200 * (fy - fz));
  }

  /// `0xFFRRGGBB` of `#RRGGBB`; null when [hex] is not one.
  static int? argbOf(String hex) {
    final match = RegExp(r'^#([0-9a-fA-F]{6})$').firstMatch(hex);
    if (match == null) return null;
    return 0xFF000000 | int.parse(match.group(1)!, radix: 16);
  }

  /// How far apart two colours look (CIE76 ΔE).
  static double distance(Lab one, Lab other) {
    final dl = one.l - other.l;
    final da = one.a - other.a;
    final db = one.b - other.b;
    return math.sqrt(dl * dl + da * da + db * db);
  }

  static double _linear(double value) => value <= 0.04045
      ? value / 12.92
      : math.pow((value + 0.055) / 1.055, 2.4).toDouble();

  static double _f(double t) => t > 216 / 24389
      ? math.pow(t, 1 / 3).toDouble()
      : (24389 / 27 * t + 16) / 116;
}
