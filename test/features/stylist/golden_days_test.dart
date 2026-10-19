import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/domain/usecases/recommend_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/services/day_weather_rules.dart';

import '../../helpers/stylist_fixtures.dart';

class _NoCatalog extends Fake implements OutfitCatalogRepository {}

/// The real days of the design (§12), from the archive's hourly weather.
DayBands _bands(String city, DateTime date, Occasion occasion) {
  final year = weatherIn(city);
  return DayWeatherRules.bands(
    year.forecast(year.indexOf(date)),
    date: date,
    occasion: occasion,
  )!;
}

Recommendation _recommend(
  DayBands day,
  DateTime date,
  Occasion occasion,
  ColourSeason? season,
) => RecommendOutfit(_NoCatalog()).choose(
  catalogFixture,
  RecommendParams(day: day, date: date, occasion: occasion, season: season),
)!;

void main() {
  const days = {
    'Denver': '2026-09-03',
    'Berlin': '2026-09-26',
    'New York': '2026-08-26',
    'Chicago': '2026-01-20',
    'Shanghai': '2026-08-05',
  };

  for (final MapEntry(key: city, value: on) in days.entries) {
    test('$city, $on: every occasion and colour season keeps the rules', () {
      final date = DateTime.parse('${on}T00:00:00Z');
      for (final occasion in Occasion.values) {
        final day = _bands(city, date, occasion);
        for (final season in [...ColourSeason.values, null]) {
          expectFollowsRules(
            _recommend(day, date, occasion, season),
            day: day,
            occasion: occasion,
            season: season,
            why: '$city $on $occasion $season',
          );
        }
      }
    });
  }

  test('Denver, 13 °C at 7 and 31 °C by 2 pm: the layer comes off, or the '
      'reason says nothing spans the day', () {
    final date = DateTime.utc(2026, 9, 3);
    final day = _bands('Denver', date, Occasion.work);
    expect((day.cold, day.warm), (WarmthBand.cool, WarmthBand.hot));
    for (final season in [...ColourSeason.values, null]) {
      final chosen = _recommend(day, date, Occasion.work, season);
      if (chosen.relaxed.contains(Relaxation.warmHours)) {
        expect(chosen.reason.kind, ReasonKind.noSpan, reason: '$season');
      } else {
        expect(chosen.reason.kind, ReasonKind.layerOff, reason: '$season');
        expect(chosen.outfit.baseWeathers, contains(WarmthBand.hot));
      }
    }
  });

  test('Chicago at −20 °C: Freezing, every outfit with a warm coat', () {
    final date = DateTime.utc(2026, 1, 20);
    final day = _bands('Chicago', date, Occasion.work);
    expect(day.cold, WarmthBand.freezing, reason: '${day.coldest}');
    for (final season in ColourSeason.values) {
      final chosen = _recommend(day, date, Occasion.work, season);
      expect(chosen.outfit.coat, isTrue, reason: chosen.outfit.id);
      expect(chosen.outfit.weathers, contains(WarmthBand.freezing));
      expect(chosen.reason.kind, isNot(ReasonKind.steady));
    }
  });
}
