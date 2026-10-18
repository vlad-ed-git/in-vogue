import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// The main colour of an outfit the person owns.
enum OutfitColour {
  black(0xFF141414),
  white(0xFFF7F7F5),
  grey(0xFF9A9A98),
  beige(0xFFD9C3A0),
  brown(0xFF7A5230),
  navy(0xFF1F2A44),
  blue(0xFF3D6FB6),
  green(0xFF3F7D4E),
  red(0xFFB3261E),
  pink(0xFFE59AB0),
  purple(0xFF6E4A9E),
  yellow(0xFFE9C23A),
  orange(0xFFE07A2E),

  /// Several colours, or a print.
  mixed(0xFF8C7A6B);

  const OutfitColour(this.argb);

  /// The swatch shown for it, as `0xFFRRGGBB`.
  final int argb;
}

/// What the person says about an outfit they own, for recommendations.
class OutfitDetails extends Equatable {
  const OutfitDetails({
    required this.name,
    required this.colour,
    required this.bands,
    required this.occasions,
    this.rain = false,
  });

  final String name;
  final OutfitColour colour;

  /// The weather it suits.
  final Set<WarmthBand> bands;

  /// Whether it suits rain.
  final bool rain;
  final Set<Occasion> occasions;

  /// Whether it says enough to recommend: a name, some weather and an
  /// occasion.
  bool get complete =>
      name.trim().isNotEmpty && bands.isNotEmpty && occasions.isNotEmpty;

  @override
  List<Object?> get props => [name, colour, bands, rain, occasions];
}

/// An outfit the person owns, from their wardrobe.
class WardrobeOutfit extends Equatable {
  const WardrobeOutfit({
    required this.id,
    required this.details,
    required this.photoUrl,
    required this.createdAt,
    this.photoPath,
  });

  final String id;
  final OutfitDetails details;

  /// The photo on the account.
  final String photoUrl;

  /// The photo's copy on this phone; null until it is saved here.
  final String? photoPath;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, details, photoUrl, photoPath, createdAt];
}
