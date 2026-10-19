import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/data/models/catalog_outfit_model.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/domain/services/candidate_rules.dart';
import 'package:in_vogue/features/stylist/domain/services/outfit_chooser.dart';
import 'package:in_vogue/features/stylist/domain/services/outfit_scorer.dart';
import 'package:in_vogue/features/stylist/domain/services/reason_rules.dart';
import 'package:in_vogue/features/stylist/domain/usecases/recommend_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/entities/hourly_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/services/day_weather_rules.dart';

import '../../helpers/catalog_outfits.dart';
import '../../helpers/stylist_fixtures.dart';

final _date = DateTime.utc(2026, 9, 3);

DayBands _day({
  WarmthBand cold = WarmthBand.mild,
  WarmthBand? warm,
  double position = 0.5,
  bool rain = false,
  bool snow = false,
  bool windy = false,
  bool indoors = false,
}) => DayBands(
  start: _date.add(const Duration(hours: 7)),
  cold: cold,
  warm: warm ?? cold,
  coldest: 13,
  coldestAt: _date.add(const Duration(hours: 7)),
  warmest: 31,
  warmestAt: _date.add(const Duration(hours: 15)),
  position: position,
  rainFrom: rain ? _date.add(const Duration(hours: 16)) : null,
  snowFrom: snow ? _date.add(const Duration(hours: 9)) : null,
  windFrom: windy ? _date.add(const Duration(hours: 11)) : null,
  indoors: indoors,
);

/// An outfit with only the fields the rules read set.
CatalogOutfit _outfit(
  String id, {
  List<String> weathers = const ['mild'],
  List<String>? baseWeathers,
  List<String> seasons = const ['softAutumn'],
  List<String> occasions = const ['work', 'casual'],
  String rain = 'fine',
  String wind = 'fine',
  double dressy = 3,
  int warmth = 3,
  List<String> kinds = const ['sweater', 'trousers'],
}) {
  final json = document(id, weathers: weathers, rain: rain);
  final pieces = (json['pieces']! as List<Object?>)
      .cast<Map<String, Object?>>();
  return CatalogOutfitModel.fromJson({
    ...json,
    'baseWeathers': baseWeathers ?? weathers,
    'seasons': seasons,
    'occasions': occasions,
    'wind': wind,
    'dressy': dressy,
    'warmth': warmth,
    'pieces': [
      for (var i = 0; i < pieces.length; i++)
        {...pieces[i], 'kind': kinds[i % kinds.length]},
    ],
  });
}

class _Catalog implements OutfitCatalogRepository {
  _Catalog(this.result);
  final Either<Failure, List<CatalogOutfit>> result;

  @override
  Future<Either<Failure, List<CatalogOutfit>>> outfits() async => result;

  @override
  Future<Either<Failure, List<CatalogOutfit>>> sample() async =>
      throw UnimplementedError();
}

List<String> _ids(Iterable<CatalogOutfit> outfits) => [
  for (final outfit in outfits) outfit.id,
];

void main() {
  group('CandidateRules', () {
    test(
      'suits the colours in the coldest hours; without a reading, the weather alone',
      () {
        final day = _day(cold: WarmthBand.cool);
        final cool = _outfit('a', weathers: ['cool']);
        final mild = _outfit('b');
        final spring = _outfit(
          'c',
          weathers: ['cool'],
          seasons: ['lightSpring'],
        );
        expect(CandidateRules.fits(cool, day, ColourSeason.softAutumn), isTrue);
        expect(
          CandidateRules.fits(mild, day, ColourSeason.softAutumn),
          isFalse,
        );
        expect(
          CandidateRules.fits(spring, day, ColourSeason.softAutumn),
          isFalse,
        );
        expect(CandidateRules.fits(spring, day, null), isTrue);
      },
    );

    test(
      'keeps the occasion, the warmest hours, the rain and snow, and leaves out refused pieces',
      () {
        final day = _day(
          cold: WarmthBand.cool,
          warm: WarmthBand.warm,
          rain: true,
        );
        final layered = _outfit(
          'layered',
          weathers: ['cool'],
          baseWeathers: ['warm', 'mild', 'cool'],
        );
        final spans = _outfit('spans', weathers: ['warm', 'mild', 'cool']);
        final coolOnly = _outfit('cool', weathers: ['cool']);
        final silk = _outfit(
          'silk',
          weathers: ['warm', 'mild', 'cool'],
          rain: 'avoid',
        );
        final lounge = _outfit(
          'lounge',
          weathers: ['warm', 'mild', 'cool'],
          occasions: ['in'],
        );
        final candidates = CandidateRules.of(
          [layered, spans, coolOnly, silk, lounge],
          day: day,
          occasion: Occasion.work,
          refused: {'everlane:spans-top'},
        );
        expect(_ids(candidates.outfits), ['layered']);
        expect(candidates.relaxed, isEmpty);
      },
    );

    test('no bare legs in snow', () {
      final day = _day(cold: WarmthBand.cold, snow: true);
      final dress = _outfit('dress', weathers: ['cold'], kinds: ['dress']);
      final trousers = _outfit('trousers', weathers: ['cold']);
      final candidates = CandidateRules.of(
        [dress, trousers],
        day: day,
        occasion: Occasion.work,
      );
      expect(_ids(candidates.outfits), ['trousers']);
    });

    test(
      'gives up the warmest hours first, then the rain, never the occasion',
      () {
        final day = _day(
          cold: WarmthBand.cool,
          warm: WarmthBand.hot,
          rain: true,
        );
        final coolSilk = _outfit('silk', weathers: ['cool'], rain: 'avoid');
        final coolMac = _outfit('mac', weathers: ['cool'], rain: 'good');
        final lounge = _outfit('lounge', weathers: ['cool'], occasions: ['in']);
        final first = CandidateRules.of(
          [coolSilk, coolMac, lounge],
          day: day,
          occasion: Occasion.work,
        );
        expect(_ids(first.outfits), ['mac']);
        expect(first.relaxed, {Relaxation.warmHours});
        final second = CandidateRules.of(
          [coolSilk, lounge],
          day: day,
          occasion: Occasion.work,
        );
        expect(_ids(second.outfits), ['silk']);
        expect(second.relaxed, {Relaxation.warmHours, Relaxation.weather});
        expect(
          CandidateRules.of(
            [lounge],
            day: day,
            occasion: Occasion.work,
          ).outfits,
          isEmpty,
        );
      },
    );
  });

  group('OutfitScorer', () {
    const scorer = OutfitScorer();

    OutfitScore scoreOf(String id, List<OutfitScore> scores) =>
        scores.firstWhere((score) => score.outfit.id == id);

    test(
      'the weather term: bands covered, and warmer outfits on a band’s cold end',
      () {
        final day = _day(
          cold: WarmthBand.cool,
          warm: WarmthBand.mild,
          position: 0,
        );
        final scores = scorer.score(
          [
            _outfit('both', weathers: ['mild', 'cool'], warmth: 2),
            _outfit('one', weathers: ['cool'], warmth: 2),
            _outfit('warmer', weathers: ['mild', 'cool'], warmth: 6),
          ],
          day: day,
          occasion: Occasion.work,
          date: _date,
        );
        expect(
          scoreOf('both', scores).weather,
          greaterThan(scoreOf('one', scores).weather),
        );
        expect(
          scoreOf('warmer', scores).weather,
          greaterThan(scoreOf('both', scores).weather),
        );
      },
    );

    test('protection from rain and wind', () {
      final scores = scorer.score(
        [
          _outfit('mac', rain: 'good'),
          _outfit('knit'),
          _outfit('loose', wind: 'avoid'),
        ],
        day: _day(rain: true, windy: true),
        occasion: Occasion.work,
        date: _date,
      );
      expect(scoreOf('mac', scores).protection, 1);
      expect(scoreOf('knit', scores).protection, 0.75);
      expect(scoreOf('loose', scores).protection, closeTo(0.35, 1e-9));
      final dry = scorer.score(
        [_outfit('loose', wind: 'avoid')],
        day: _day(),
        occasion: Occasion.work,
        date: _date,
      );
      expect(dry.single.protection, 1);
    });

    test('dressiness aims at the occasion', () {
      final day = _day();
      final work = scorer.score(
        [_outfit('suit', dressy: 3), _outfit('tee', dressy: 1.5)],
        day: day,
        occasion: Occasion.work,
        date: _date,
      );
      expect(scoreOf('suit', work).dressiness, 1);
      expect(scoreOf('tee', work).dressiness, lessThan(0.5));
    });

    test('pieces worn lately rest; a plain neutral rests half as long', () {
      final knit = _outfit('knit');
      final history = OutfitHistory(
        worn: [
          WornDay(
            date: _date.subtract(const Duration(days: 2)),
            pieces: {'everlane:knit-top'},
          ),
        ],
      );
      final rested = scorer.score(
        [knit],
        day: _day(),
        occasion: Occasion.work,
        date: _date,
      );
      final tired = scorer.score(
        [knit],
        day: _day(),
        occasion: Occasion.work,
        date: _date,
        history: history,
      );
      expect(rested.single.rest, 1);
      // The fixture's top is a plain neutral: two days is one half-life.
      expect(tired.single.rest, closeTo(0.5, 1e-9));
      final old = OutfitHistory(
        worn: [
          WornDay(
            date: _date.subtract(const Duration(days: 15)),
            pieces: {'everlane:knit-top'},
          ),
        ],
      );
      expect(
        scorer
            .score(
              [knit],
              day: _day(),
              occasion: Occasion.work,
              date: _date,
              history: old,
            )
            .single
            .rest,
        1,
      );
    });

    test('the total weighs the terms as the design does', () {
      final score = scorer
          .score(
            [_outfit('a')],
            day: _day(),
            occasion: Occasion.work,
            date: _date,
          )
          .single;
      expect(
        score.total,
        closeTo(
          3 * score.weather +
              1.5 * score.protection +
              score.dressiness +
              2 * score.taste +
              score.rest,
          1e-9,
        ),
      );
      expect(score.taste, 0.5);
    });
  });

  group('OutfitChooser', () {
    OutfitScore score(String id, double total) => OutfitScore(
      outfit: _outfit(id),
      total: total,
      weather: 0,
      protection: 0,
      dressiness: 0,
      taste: 0,
      rest: 0,
    );

    test('the best outfit never suggested, within 15% of the day’s best', () {
      final scores = [score('a', 8), score('b', 7.5), score('c', 6.5)];
      expect(OutfitChooser.choose(scores)!.outfit.id, 'a');
      expect(
        OutfitChooser.choose(scores, suggestedAt: {'a': _date})!.outfit.id,
        'b',
      );
      // c is below 85% of the best, so it never comes first.
      expect(
        OutfitChooser.choose(
          scores,
          suggestedAt: {'a': _date, 'b': _date},
        )!.outfit.id,
        'a',
      );
    });

    test('when every one was suggested, the one suggested longest ago', () {
      final scores = [score('a', 8), score('b', 7.5)];
      expect(
        OutfitChooser.choose(
          scores,
          suggestedAt: {
            'a': _date,
            'b': _date.subtract(const Duration(days: 9)),
          },
        )!.outfit.id,
        'b',
      );
      expect(OutfitChooser.shortlistOf(scores), hasLength(2));
      expect(OutfitChooser.choose(const []), isNull);
    });

    test('ties go to the higher score, then the lower id', () {
      expect(
        OutfitChooser.choose([score('b', 8), score('a', 8)])!.outfit.id,
        'a',
      );
    });
  });

  group('ReasonRules', () {
    ReasonKind kindOf(
      CatalogOutfit outfit,
      DayBands day, {
      Set<Relaxation> relaxed = const {},
    }) => ReasonRules.of(outfit, day: day, relaxed: relaxed).kind;

    test('names what matters most about the day', () {
      final layered = _outfit(
        'a',
        weathers: ['cool'],
        baseWeathers: ['hot', 'warm', 'mild', 'cool'],
        rain: 'good',
      );
      final swing = _day(
        cold: WarmthBand.cool,
        warm: WarmthBand.hot,
        rain: true,
      );
      expect(kindOf(layered, swing), ReasonKind.layerOff);
      expect(
        kindOf(layered, swing, relaxed: {Relaxation.warmHours}),
        ReasonKind.noSpan,
      );
      expect(
        kindOf(
          layered,
          swing,
          relaxed: {Relaxation.warmHours, Relaxation.weather},
        ),
        ReasonKind.noWeatherMatch,
      );
      expect(kindOf(layered, _day(rain: true)), ReasonKind.rain);
      expect(kindOf(_outfit('b'), _day(rain: true)), ReasonKind.steady);
      expect(
        kindOf(
          _outfit('c', weathers: ['freezing']),
          _day(cold: WarmthBand.freezing, snow: true),
        ),
        ReasonKind.snow,
      );
      expect(
        kindOf(
          _outfit('d', weathers: ['freezing']),
          _day(cold: WarmthBand.freezing),
        ),
        ReasonKind.freezing,
      );
      expect(kindOf(_outfit('e'), _day(windy: true)), ReasonKind.wind);
      expect(kindOf(_outfit('f'), _day(indoors: true)), ReasonKind.home);
    });

    test('rain from the first hour is there all day; later rain says when', () {
      final later = ReasonRules.of(
        _outfit('a', rain: 'good'),
        day: _day(rain: true),
      );
      expect(later.from, _date.add(const Duration(hours: 16)));
      final early = DayBands(
        start: _date.add(const Duration(hours: 7)),
        cold: WarmthBand.mild,
        warm: WarmthBand.mild,
        coldest: 15,
        coldestAt: _date.add(const Duration(hours: 7)),
        warmest: 18,
        warmestAt: _date.add(const Duration(hours: 14)),
        position: 0.2,
        rainFrom: _date.add(const Duration(hours: 6)),
      );
      expect(
        ReasonRules.of(_outfit('a', rain: 'good'), day: early).from,
        isNull,
      );
    });
  });

  group('RecommendOutfit', () {
    test('chooses from the catalog for the day and says why', () async {
      final recommend = RecommendOutfit(
        _Catalog(
          Right([
            _outfit('a'),
            _outfit('b', seasons: ['trueWinter']),
          ]),
        ),
      );
      final result = await recommend(
        RecommendParams(
          day: _day(),
          date: _date,
          occasion: Occasion.work,
          season: ColourSeason.softAutumn,
        ),
      );
      final chosen = result.getOrElse(() => throw StateError('$result'))!;
      expect(chosen.outfit.id, 'a');
      expect(chosen.reason.season, ColourSeason.softAutumn);
      expect((chosen.candidates, chosen.shortlist), (1, 1));
    });

    test(
      'none when nothing suits the day, and the catalog’s failure when it can’t be read',
      () async {
        final none = await RecommendOutfit(
          _Catalog(
            Right([
              _outfit('a', occasions: ['in']),
            ]),
          ),
        )(RecommendParams(day: _day(), date: _date, occasion: Occasion.work));
        expect(none, const Right<Failure, Recommendation?>(null));
        final offline = await RecommendOutfit(
          _Catalog(const Left(NetworkFailure())),
        )(RecommendParams(day: _day(), date: _date, occasion: Occasion.work));
        expect(offline, const Left<Failure, Recommendation?>(NetworkFailure()));
      },
    );
  });

  // Seeded random days from −30 to 42 °C, with swings, rain, snow and wind,
  // for every occasion and colour season, on the real catalog.
  test('random days never break a rule', () {
    final random = Random(20261019);
    final recommend = RecommendOutfit(_Catalog(Right(catalogFixture)));
    var checked = 0;
    for (var round = 0; round < 400; round++) {
      final low = -30 + random.nextDouble() * 60;
      final swing = random.nextDouble() * 18;
      final rainy = random.nextInt(4) == 0;
      final snowy = random.nextInt(6) == 0;
      final gusty = random.nextInt(5) == 0;
      final forecast = Forecast(
        hours: [
          for (var hour = 0; hour < 24; hour++)
            HourlyWeather(
              time: _date.add(Duration(hours: hour)),
              temperature: 0,
              feelsLike: (low + swing * sin(pi * (hour - 6) / 18).clamp(0, 1))
                  .clamp(-30, 42)
                  .toDouble(),
              precipitationProbability: rainy || snowy ? 90 : 0,
              precipitation: rainy && hour > 12 ? 2 : 0,
              snowfall: snowy && hour > 8 ? 1 : 0,
              weatherCode: snowy && hour > 8
                  ? 73
                  : (rainy && hour > 12 ? 63 : 2),
              windGusts: gusty && hour > 10 ? 55 : 15,
            ),
        ],
        utcOffset: Duration.zero,
        fetchedAt: _date,
      );
      for (final occasion in Occasion.values) {
        final day = DayWeatherRules.bands(
          forecast,
          date: _date,
          occasion: occasion,
        )!;
        for (final season in [...ColourSeason.values, null]) {
          final chosen = recommend.choose(
            catalogFixture,
            RecommendParams(
              day: day,
              date: _date,
              occasion: occasion,
              season: season,
            ),
          );
          final why =
              'round $round, ${low.toStringAsFixed(1)} °C +$swing $occasion $season';
          expect(chosen, isNotNull, reason: 'nothing for $why');
          expectFollowsRules(
            chosen!,
            day: day,
            occasion: occasion,
            season: season,
            why: why,
          );
          checked++;
        }
      }
    }
    expect(checked, 400 * 4 * 13);
  });
}
