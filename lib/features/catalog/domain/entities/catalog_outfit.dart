import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_pass.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// How a piece, or a whole outfit, does in rain.
enum RainFit { good, fine, avoid }

/// How a piece, or a whole outfit, does in wind.
enum WindFit { fine, avoid }

/// What a piece is in its outfit.
enum PieceRole { whole, top, bottom, over }

/// How warm a piece is.
enum PieceWarmth { light, medium, warm, veryWarm }

/// How a colour is laid out on a piece.
enum ColourPattern { plain, striped, checked, printed }

/// One piece of a catalog outfit, as the shop sells it.
class OutfitPiece extends Equatable {
  const OutfitPiece({
    required this.colourway,
    required this.style,
    required this.name,
    required this.colour,
    required this.hex,
    required this.family,
    required this.pattern,
    required this.neutral,
    required this.role,
    required this.kind,
    required this.weathers,
    required this.warmth,
    required this.dressy,
    required this.styles,
    required this.rain,
    required this.wind,
    required this.productUrl,
    required this.photoUrl,
    this.accent,
  });

  /// The colourway's id, such as "everlane:womens-cotton-crew-black".
  final String colourway;

  /// The style it is one colour of.
  final String style;
  final String name;

  /// The colour's name at the shop.
  final String colour;

  /// 0xAARRGGBB.
  final int hex;

  /// The colour's family, such as "navy".
  final String family;

  /// A stripe's, check's or print's second family.
  final String? accent;
  final ColourPattern pattern;
  final bool neutral;
  final PieceRole role;

  /// What it is, such as "trousers" or "puffer".
  final String kind;

  /// Every weather it can be worn in, layered if needed.
  final Set<WarmthBand> weathers;
  final PieceWarmth warmth;

  /// 1 (lounging) to 5 (an event).
  final double dressy;
  final Set<String> styles;
  final RainFit rain;
  final WindFit wind;

  /// The piece's page at the shop.
  final String productUrl;

  /// The piece worn by a model.
  final String photoUrl;

  @override
  List<Object?> get props => [
    colourway,
    style,
    name,
    colour,
    hex,
    family,
    accent,
    pattern,
    neutral,
    role,
    kind,
    weathers,
    warmth,
    dressy,
    styles,
    rain,
    wind,
    productUrl,
    photoUrl,
  ];
}

/// An outfit of the curated catalog, with what it suits.
class CatalogOutfit extends Equatable {
  const CatalogOutfit({
    required this.id,
    required this.order,
    required this.name,
    required this.sample,
    required this.imageUrl,
    required this.weathers,
    required this.baseWeathers,
    required this.seasons,
    required this.occasions,
    required this.families,
    required this.styles,
    required this.kinds,
    required this.dressy,
    required this.warmth,
    required this.rain,
    required this.wind,
    required this.coat,
    required this.pieces,
    required this.passes,
  });

  /// Such as "o0181".
  final String id;

  /// Its place in the catalog's mixed order.
  final int order;
  final String name;

  /// Whether it is in the onboarding sample.
  final bool sample;

  /// Its picture, the main piece's model photo.
  final String imageUrl;

  /// The weathers it suits as it is.
  final Set<WarmthBand> weathers;

  /// The weathers it suits with its layers off.
  final Set<WarmthBand> baseWeathers;

  /// The colour seasons it suits.
  final Set<ColourSeason> seasons;

  /// The app's occasions it suits.
  final Set<Occasion> occasions;

  /// Its colour families, styles and kinds of piece.
  final Set<String> families;
  final Set<String> styles;
  final Set<String> kinds;

  /// Its pieces' mean dressiness, 1 to 5.
  final double dressy;

  /// How warm it is, its pieces' warmth added up.
  final int warmth;
  final RainFit rain;
  final WindFit wind;

  /// Whether it has a coat, a jacket or a puffer.
  final bool coat;
  final List<OutfitPiece> pieces;

  /// Try-on passes, in order.
  final List<TryOnPass> passes;

  /// The pieces from the outer layer in: the try-on's passes in reverse.
  List<OutfitPiece> get outsideIn {
    final byColourway = {for (final piece in pieces) piece.colourway: piece};
    return [for (final pass in passes.reversed) ?byColourway[pass.piece]];
  }

  @override
  List<Object?> get props => [
    id,
    order,
    name,
    sample,
    imageUrl,
    weathers,
    baseWeathers,
    seasons,
    occasions,
    families,
    styles,
    kinds,
    dressy,
    warmth,
    rain,
    wind,
    coat,
    pieces,
    passes,
  ];
}
