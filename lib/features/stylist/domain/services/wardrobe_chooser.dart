import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';

/// The person's own outfit for a day (design §9): the catalog's weather and
/// occasion rules, without the colour season, since they are the person's
/// own clothes. They need no try-on.
abstract final class WardrobeChooser {
  /// Of [outfits], one for [occasion] and the day's coldest hours, and its
  /// warmest hours too when one suits them; on a wet day one for rain
  /// first. A different one each day, and not [avoid] (the other day's)
  /// when another suits. Null when none suits.
  static WardrobeOutfit? choose(
    List<WardrobeOutfit> outfits, {
    required DayBands day,
    required Occasion occasion,
    required DateTime date,
    String? avoid,
  }) {
    final fitting = [
      for (final outfit in outfits)
        if (outfit.details.occasions.contains(occasion) &&
            outfit.details.bands.contains(day.cold))
          outfit,
    ];
    final spanning = [
      for (final outfit in fitting)
        if (day.warm == day.cold || outfit.details.bands.contains(day.warm))
          outfit,
    ];
    var candidates = spanning.isEmpty ? fitting : spanning;
    if (day.rain || day.snow) {
      final forRain = [
        for (final outfit in candidates)
          if (outfit.details.rain) outfit,
      ];
      if (forRain.isNotEmpty) candidates = forRain;
    }
    if (candidates.length > 1) {
      candidates = [
        for (final outfit in candidates)
          if (outfit.id != avoid) outfit,
      ];
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => a.id.compareTo(b.id));
    final days =
        date.toUtc().millisecondsSinceEpoch ~/ Duration.millisecondsPerDay;
    return candidates[days % candidates.length];
  }
}
