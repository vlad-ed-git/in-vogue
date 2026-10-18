import 'package:in_vogue/features/colours/domain/services/colour_space.dart';

/// Names of clothing colours, and the nearest one for any colour, so a
/// palette's swatches can be told apart in words.
abstract final class ColourNames {
  /// Each name's own colour, as `0xFFRRGGBB`.
  static const named = <String, int>{
    'white': 0xFFFFFFFF,
    'ivory': 0xFFFFFFF0,
    'cream': 0xFFF3E9DC,
    'stone': 0xFFD8C8B0,
    'beige': 0xFFD9C3A0,
    'sand': 0xFFC2B280,
    'camel': 0xFFC19A6B,
    'tan': 0xFFD2B48C,
    'taupe': 0xFF8E7F6E,
    'greige': 0xFFA39E98,
    'lightGrey': 0xFFD6D6D6,
    'silver': 0xFFC0C0C0,
    'grey': 0xFF9E9E9E,
    'charcoal': 0xFF36454F,
    'black': 0xFF000000,
    'chocolate': 0xFF4E2A1E,
    'espresso': 0xFF3B2F2F,
    'coffee': 0xFF6B4423,
    'brown': 0xFF8B5A2B,
    'cinnamon': 0xFFA0522D,
    'rust': 0xFFB7410E,
    'brick': 0xFF9E3B26,
    'terracotta': 0xFFC4704F,
    'burntOrange': 0xFFCC5500,
    'orange': 0xFFFF8C00,
    'apricot': 0xFFF2B07B,
    'peach': 0xFFF9C6A8,
    'salmon': 0xFFFA8072,
    'coral': 0xFFFF7F50,
    'poppy': 0xFFF04E31,
    'red': 0xFFD2042D,
    'burgundy': 0xFF800020,
    'wine': 0xFF722F37,
    'blush': 0xFFF4B6C2,
    'orchid': 0xFFE6A8C2,
    'dustyRose': 0xFFC9A9A6,
    'mauve': 0xFFB57F8C,
    'raspberry': 0xFFC2185B,
    'berry': 0xFFB5446E,
    'fuchsia': 0xFFFF1493,
    'hotPink': 0xFFFF66CC,
    'watermelon': 0xFFFF85A1,
    'lemon': 0xFFFFF44F,
    'buttercup': 0xFFFBD98C,
    'mustard': 0xFFE1AD01,
    'gold': 0xFFDAA520,
    'ochre': 0xFFCC7722,
    'mint': 0xFFA8D5BA,
    'sage': 0xFF9CAF88,
    'moss': 0xFF8A9A5B,
    'olive': 0xFF708238,
    'khaki': 0xFFB39B72,
    'leafGreen': 0xFF7AC143,
    'lime': 0xFFC1D82F,
    'emerald': 0xFF009B77,
    'jade': 0xFF00A86B,
    'forestGreen': 0xFF2E5E3F,
    'pine': 0xFF01796F,
    'teal': 0xFF00827F,
    'deepTeal': 0xFF00544F,
    'turquoise': 0xFF2EB7A5,
    'aqua': 0xFF8ED1C6,
    'skyBlue': 0xFF8FB8DE,
    'powderBlue': 0xFFAFCBEA,
    'periwinkle': 0xFF9FB7D9,
    'cornflower': 0xFF7FA7C9,
    'denim': 0xFF3E5C8A,
    'slateBlue': 0xFF5B7DB1,
    'royalBlue': 0xFF4169E1,
    'cobalt': 0xFF0047AB,
    'azure': 0xFF0096FF,
    'navy': 0xFF1F2A44,
    'midnight': 0xFF191970,
    'lavender': 0xFFC3B1E1,
    'lilac': 0xFFD3C4E3,
    'violet': 0xFF7F00FF,
    'purple': 0xFF6A0DAD,
    'plum': 0xFF614051,
    'aubergine': 0xFF3D0C45,
  };

  static final _labs = {
    for (final MapEntry(:key, :value) in named.entries)
      key: ColourSpace.labOf(value),
  };

  /// The name nearest [argb].
  static String nameOf(int argb) {
    final lab = ColourSpace.labOf(argb);
    String? nearest;
    var shortest = double.infinity;
    for (final MapEntry(key: name, value: named) in _labs.entries) {
      final distance = ColourSpace.distance(lab, named);
      if (distance < shortest) {
        shortest = distance;
        nearest = name;
      }
    }
    return nearest!;
  }
}
