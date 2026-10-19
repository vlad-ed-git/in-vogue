import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';

/// Which catalog outfits may be worn on a day (design §7.3).
abstract final class CandidateRules {
  /// Kinds of piece worn with bare legs: the catalog has no tights.
  static const bareLegs = {'dress', 'skirt', 'shorts'};

  /// Whether [outfit] suits [season] in the day's coldest hours, worn as it
  /// is. Without a [season], the weather alone decides.
  static bool fits(CatalogOutfit outfit, DayBands day, ColourSeason? season) =>
      outfit.weathers.contains(day.cold) &&
      (season == null || outfit.seasons.contains(season));

  /// Whether [outfit] leaves the legs bare.
  static bool bareLegged(CatalogOutfit outfit) =>
      outfit.pieces.any((piece) => bareLegs.contains(piece.kind));

  /// Of the [fitting] outfits, those for [occasion] without a [refused]
  /// piece that suit the day's warmest hours, as worn or with the layer
  /// off, and keep clear of rain-shy pieces in rain and of bare legs in
  /// snow. When none is left, the warmest hours give way first, then the
  /// rain and snow; the occasion and the refused pieces never do.
  static ({List<CatalogOutfit> outfits, Set<Relaxation> relaxed}) of(
    Iterable<CatalogOutfit> fitting, {
    required DayBands day,
    required Occasion occasion,
    Set<String> refused = const {},
  }) {
    final allowed = [
      for (final outfit in fitting)
        if (outfit.occasions.contains(occasion) &&
            !outfit.pieces.any((piece) => refused.contains(piece.colourway)))
          outfit,
    ];
    bool warmHours(CatalogOutfit outfit) =>
        day.warm == day.cold ||
        outfit.weathers.contains(day.warm) ||
        outfit.baseWeathers.contains(day.warm);
    bool weather(CatalogOutfit outfit) =>
        !(day.rain && outfit.rain == RainFit.avoid) &&
        !(day.snow && bareLegged(outfit));
    for (final relaxed in const [
      <Relaxation>{},
      {Relaxation.warmHours},
      {Relaxation.warmHours, Relaxation.weather},
    ]) {
      final outfits = [
        for (final outfit in allowed)
          if ((relaxed.contains(Relaxation.warmHours) || warmHours(outfit)) &&
              (relaxed.contains(Relaxation.weather) || weather(outfit)))
            outfit,
      ];
      if (outfits.isNotEmpty) return (outfits: outfits, relaxed: relaxed);
    }
    return (outfits: const [], relaxed: const {});
  }
}
