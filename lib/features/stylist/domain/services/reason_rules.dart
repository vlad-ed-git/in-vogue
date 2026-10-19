import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

/// Why an outfit suits its day, from the day's facts and the outfit's
/// fields (design §7.7): the first that holds of a rule given up, the layer
/// coming off, snow, rain the outfit takes, freezing, wind it takes, a day
/// at home, or the day's range.
abstract final class ReasonRules {
  static OutfitReason of(
    CatalogOutfit outfit, {
    required DayBands day,
    Set<Relaxation> relaxed = const {},
    ColourSeason? season,
  }) {
    final (kind, from) = switch (outfit) {
      _ when relaxed.contains(Relaxation.weather) => (
        ReasonKind.noWeatherMatch,
        day.snowFrom ?? day.rainFrom,
      ),
      _ when relaxed.contains(Relaxation.warmHours) => (
        ReasonKind.noSpan,
        null,
      ),
      _
          when day.warm != day.cold &&
              !outfit.weathers.contains(day.warm) &&
              outfit.baseWeathers.contains(day.warm) =>
        (ReasonKind.layerOff, null),
      _ when day.snow => (ReasonKind.snow, day.snowFrom),
      _ when day.rain && outfit.rain == RainFit.good => (
        ReasonKind.rain,
        day.rainFrom,
      ),
      _ when day.cold == WarmthBand.freezing => (ReasonKind.freezing, null),
      _ when day.windy && outfit.wind == WindFit.fine => (
        ReasonKind.wind,
        day.windFrom,
      ),
      _ when day.indoors => (ReasonKind.home, null),
      _ => (ReasonKind.steady, null),
    };
    return OutfitReason(
      kind: kind,
      coldest: day.coldest,
      coldestAt: day.coldestAt,
      warmest: day.warmest,
      warmestAt: day.warmestAt,
      // What comes with the first hour is there all day.
      from: from == null || from.isBefore(day.start) ? null : from,
      season: season,
    );
  }
}
