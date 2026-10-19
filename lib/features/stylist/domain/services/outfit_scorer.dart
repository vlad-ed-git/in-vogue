import 'dart:math' as math;

import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';

/// How much each term of an outfit's score counts (design §7.4).
class StylistWeights extends Equatable {
  const StylistWeights({
    this.weather = 3,
    this.protection = 1.5,
    this.dressiness = 1,
    this.taste = 2,
    this.rest = 1,
  });

  final double weather;
  final double protection;
  final double dressiness;
  final double taste;
  final double rest;

  double get total => weather + protection + dressiness + taste + rest;

  @override
  List<Object?> get props => [weather, protection, dressiness, taste, rest];
}

/// An outfit's score for a day: each term 0 to 1, and their weighted sum.
class OutfitScore extends Equatable {
  const OutfitScore({
    required this.outfit,
    required this.total,
    required this.weather,
    required this.protection,
    required this.dressiness,
    required this.taste,
    required this.rest,
  });

  final CatalogOutfit outfit;
  final double total;
  final double weather;
  final double protection;
  final double dressiness;
  final double taste;
  final double rest;

  @override
  List<Object?> get props => [
    outfit,
    total,
    weather,
    protection,
    dressiness,
    taste,
    rest,
  ];
}

/// Scores the candidates for a day: how well each fits the day's weather,
/// keeps out its rain and wind, matches the occasion's dressiness and the
/// person's taste, and rests the pieces worn lately.
class OutfitScorer {
  const OutfitScorer([this.weights = const StylistWeights()]);

  final StylistWeights weights;

  /// The dressiness each occasion aims at, 1 to 5.
  static const dressyTargets = {
    Occasion.stayingIn: 1.0,
    Occasion.casual: 2.0,
    Occasion.work: 3.0,
    Occasion.goingOut: 3.0,
  };

  /// Days a worn piece takes to rest halfway; a plain neutral, half as long.
  static const restHalfLife = 4.0;

  /// Days of made outfits the rest looks back on.
  static const restDays = 14;

  List<OutfitScore> score(
    List<CatalogOutfit> candidates, {
    required DayBands day,
    required Occasion occasion,
    required DateTime date,
    OutfitHistory history = const OutfitHistory(),
    double Function(CatalogOutfit outfit)? taste,
  }) {
    final warmths = {for (final outfit in candidates) outfit.warmth}.toList()
      ..sort();
    // On a band's cold end, the warmer candidates fit best.
    final aim = 1 - day.position;
    final span = day.span;
    // Days since each piece was last worn, within the rest's reach.
    final daysSince = <String, double>{};
    for (final worn in history.worn) {
      if (!worn.date.isBefore(date)) continue;
      final days = date.difference(worn.date).inHours / 24;
      if (days > restDays) continue;
      for (final piece in worn.pieces) {
        final known = daysSince[piece];
        if (known == null || days < known) daysSince[piece] = days;
      }
    }
    return [
      for (final outfit in candidates)
        _score(
          outfit,
          covered:
              span
                  .where(
                    (band) =>
                        outfit.weathers.contains(band) ||
                        outfit.baseWeathers.contains(band),
                  )
                  .length /
              span.length,
          placement:
              1 -
              ((warmths.length == 1
                          ? aim
                          : warmths.indexOf(outfit.warmth) /
                                (warmths.length - 1)) -
                      aim)
                  .abs(),
          day: day,
          occasion: occasion,
          daysSince: daysSince,
          taste: taste?.call(outfit) ?? 0.5,
        ),
    ];
  }

  OutfitScore _score(
    CatalogOutfit outfit, {
    required double covered,
    required double placement,
    required DayBands day,
    required Occasion occasion,
    required Map<String, double> daysSince,
    required double taste,
  }) {
    final weather = 0.6 * covered + 0.4 * placement;
    final wet = day.rain || day.snow;
    final rain = switch (outfit.rain) {
      RainFit.good => 1.0,
      RainFit.fine => 0.5,
      RainFit.avoid => 0.0,
    };
    final wind = switch (outfit.wind) {
      WindFit.fine => 1.0,
      WindFit.avoid => 0.2,
    };
    final protection = switch ((wet, day.windy)) {
      (true, true) => (rain + wind) / 2,
      (true, false) => rain,
      (false, true) => wind,
      (false, false) => 1.0,
    };
    final target = dressyTargets[occasion]!;
    final dressiness = math
        .exp(-math.pow(outfit.dressy - target, 2) / 2)
        .toDouble();
    var tired = 0.0;
    for (final piece in outfit.pieces) {
      final days = daysSince[piece.colourway];
      if (days == null) continue;
      final halfLife = piece.neutral && piece.pattern == ColourPattern.plain
          ? restHalfLife / 2
          : restHalfLife;
      tired = math.max(tired, math.pow(0.5, days / halfLife).toDouble());
    }
    final rest = 1 - tired;
    return OutfitScore(
      outfit: outfit,
      total:
          weights.weather * weather +
          weights.protection * protection +
          weights.dressiness * dressiness +
          weights.taste * taste +
          weights.rest * rest,
      weather: weather,
      protection: protection,
      dressiness: dressiness,
      taste: taste,
      rest: rest,
    );
  }
}
