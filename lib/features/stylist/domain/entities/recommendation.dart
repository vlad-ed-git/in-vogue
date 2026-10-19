import 'package:equatable/equatable.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';

/// The pieces of an outfit made for a day.
class WornDay extends Equatable {
  const WornDay({required this.date, required this.pieces});

  /// Midnight UTC of the local date.
  final DateTime date;

  /// Colourway ids.
  final Set<String> pieces;

  @override
  List<Object?> get props => [date, pieces];
}

/// What the person was suggested, and what they wore lately.
class OutfitHistory extends Equatable {
  const OutfitHistory({this.suggestedAt = const {}, this.worn = const []});

  /// When each outfit id was last suggested.
  final Map<String, DateTime> suggestedAt;

  /// The outfits made on recent days.
  final List<WornDay> worn;

  @override
  List<Object?> get props => [suggestedAt, worn];
}

/// A rule the candidates gave up, when no outfit met them all.
enum Relaxation {
  /// Suiting the day's warmest hours, as worn or without the layer.
  warmHours,

  /// Keeping clear of rain-shy pieces in rain, and bare legs in snow.
  weather,
}

/// What a reason says about the day and the outfit.
enum ReasonKind {
  /// Nothing suited the day's rain or snow in the person's colours.
  noWeatherMatch,

  /// Nothing spanned the day's coldest and warmest hours.
  noSpan,

  /// Cold morning, warm afternoon: the layer comes off.
  layerOff,
  snow,
  rain,
  freezing,
  wind,

  /// A day at home.
  home,

  /// One band all day, or a span the outfit covers as it is.
  steady,
}

/// Why an outfit was chosen, as facts the screen words.
class OutfitReason extends Equatable {
  const OutfitReason({
    required this.kind,
    required this.coldest,
    required this.coldestAt,
    required this.warmest,
    required this.warmestAt,
    this.from,
    this.season,
  });

  final ReasonKind kind;

  /// Feels-like, °C, and when.
  final double coldest;
  final DateTime coldestAt;
  final double warmest;
  final DateTime warmestAt;

  /// When the rain, snow or wind starts; null when it starts with the day.
  final DateTime? from;

  /// The colour season the outfit was chosen for; null without a clear
  /// reading.
  final ColourSeason? season;

  @override
  List<Object?> get props => [
    kind,
    coldest,
    coldestAt,
    warmest,
    warmestAt,
    from,
    season,
  ];
}

/// The outfit chosen for a day and an occasion, and why.
class Recommendation extends Equatable {
  const Recommendation({
    required this.outfit,
    required this.reason,
    required this.score,
    required this.candidates,
    required this.shortlist,
    this.relaxed = const {},
  });

  final CatalogOutfit outfit;
  final OutfitReason reason;

  /// Its score, out of the weights' sum.
  final double score;

  /// How many outfits it was chosen from.
  final int candidates;

  /// How many of them scored within 15% of the day's best.
  final int shortlist;
  final Set<Relaxation> relaxed;

  @override
  List<Object?> get props => [
    outfit,
    reason,
    score,
    candidates,
    shortlist,
    relaxed,
  ];
}
