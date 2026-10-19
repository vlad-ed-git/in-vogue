import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/domain/usecases/recommend_outfit.dart';
import 'package:in_vogue/features/weather/domain/services/day_weather_rules.dart';

import '../../helpers/stylist_fixtures.dart';

/// Today's outfits, 1,749 in the bundled knowledge base, average this many
/// try-on passes.
const _todaysMeanPasses = 2.544;

void main() {
  // A year of real weather in ten cities, for every colour season and none,
  // and every occasion, one person each, wearing what is recommended.
  test('a year in ten cities breaks no rule, follows the owner’s choice rule '
      'and keeps today’s cost', () {
    final recommend = RecommendOutfit(_NoCatalog());
    var days = 0;
    var passes = 0;
    var repeats = 0;
    var unexplained = 0;
    var wideDays = 0;
    var wideRepeats = 0;
    final relaxed = <Relaxation, int>{};
    final worst = <String>[];
    for (final year in weatherYears) {
      for (final season in [...ColourSeason.values, null]) {
        for (final occasion in Occasion.values) {
          final suggestedAt = <String, DateTime>{};
          final worn = <WornDay>[];
          final uses = <String, int>{};
          for (var index = 0; index < year.days; index++) {
            final date = year.date(index);
            final day = DayWeatherRules.bands(
              year.forecast(index),
              date: date,
              occasion: occasion,
            )!;
            final chosen = recommend.choose(
              catalogFixture,
              RecommendParams(
                day: day,
                date: date,
                occasion: occasion,
                season: season,
                history: OutfitHistory(suggestedAt: suggestedAt, worn: worn),
              ),
            );
            final why = '${year.name} $date $occasion $season';
            expect(chosen, isNotNull, reason: 'nothing for $why');
            expectFollowsRules(
              chosen!,
              day: day,
              occasion: occasion,
              season: season,
              why: why,
            );
            final id = chosen.outfit.id;
            final last = suggestedAt[id];
            final repeat = last != null && date.difference(last).inDays < 30;
            if (repeat) {
              repeats++;
              // The owner's rule repeats an outfit only when every one
              // within 15% of the day's best was suggested already.
              if (chosen.shortlist > 30) unexplained++;
            }
            if (chosen.candidates >= 30) {
              wideDays++;
              if (repeat) wideRepeats++;
            }
            for (final kind in chosen.relaxed) {
              relaxed[kind] = (relaxed[kind] ?? 0) + 1;
            }
            suggestedAt[id] = date;
            worn
              ..add(
                WornDay(
                  date: date,
                  pieces: {
                    for (final piece in chosen.outfit.pieces) piece.colourway,
                  },
                ),
              )
              ..removeWhere((day) => date.difference(day.date).inDays > 14);
            uses[id] = (uses[id] ?? 0) + 1;
            days++;
            passes += chosen.outfit.passes.length;
          }
          final most = uses.values.reduce((a, b) => a > b ? a : b);
          if (most > year.days * 0.05) {
            worst.add('${year.name} $occasion $season: $most');
          }
        }
      }
    }
    final summary =
        'days $days, repeats within 30 days $repeats, on days with 30+ '
        'candidates $wideRepeats of $wideDays, mean passes '
        '${(passes / days).toStringAsFixed(3)}, relaxed $relaxed, runs with '
        'an outfit on over 5% of days ${worst.length}';
    expect(days, 10 * 13 * 4 * 365);
    expect(unexplained, 0, reason: summary);
    // Where 30 or more outfits suit a day, one comes back within 30 days
    // only when fewer than 30 score within 15% of the day's best.
    expect(wideRepeats, lessThan(wideDays * 0.01), reason: summary);
    expect(
      passes / days,
      lessThanOrEqualTo(_todaysMeanPasses),
      reason: summary,
    );
    // Rules are given up only when nothing meets them all.
    expect(
      relaxed.values.fold(0, (a, b) => a + b),
      lessThan(days * 0.01),
      reason: summary,
    );
  });
}

/// The use case reads no repository here: [RecommendOutfit.choose] takes
/// the catalog.
class _NoCatalog extends Fake implements OutfitCatalogRepository {}
