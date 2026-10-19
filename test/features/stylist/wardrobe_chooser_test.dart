import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/stylist/domain/services/wardrobe_chooser.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';

import '../../helpers/day_bands.dart';

final _date = DateTime.utc(2026, 10, 19);

WardrobeOutfit _own(
  String id, {
  Set<WarmthBand> bands = const {WarmthBand.mild},
  Set<Occasion> occasions = const {Occasion.work},
  bool rain = false,
}) => WardrobeOutfit(
  id: id,
  details: OutfitDetails(
    name: 'Outfit $id',
    colours: const {OutfitColour.navy},
    bands: bands,
    rain: rain,
    occasions: occasions,
  ),
  photoUrl: 'https://example.invalid/$id.jpg',
  createdAt: _date,
);

DayBands _swing(WarmthBand cold, WarmthBand warm) {
  final day = bandsFor(cold);
  return DayBands(
    start: day.start,
    cold: cold,
    warm: warm,
    coldest: day.coldest,
    coldestAt: day.coldestAt,
    warmest: day.warmest + 8,
    warmestAt: day.warmestAt.add(const Duration(hours: 7)),
    position: day.position,
  );
}

void main() {
  WardrobeOutfit? choose(
    List<WardrobeOutfit> outfits, {
    DayBands? day,
    Occasion occasion = Occasion.work,
    DateTime? date,
    String? avoid,
  }) => WardrobeChooser.choose(
    outfits,
    day: day ?? bandsFor(WarmthBand.mild),
    occasion: occasion,
    date: date ?? _date,
    avoid: avoid,
  );

  test(
    'keeps to the occasion and the coldest hours; no colours are judged',
    () {
      final outfits = [
        _own('a', occasions: {Occasion.casual}),
        _own('b', bands: {WarmthBand.hot}),
        _own('c'),
      ];
      expect(choose(outfits)?.id, 'c');
      expect(choose(outfits, day: bandsFor(WarmthBand.freezing)), isNull);
      expect(choose(const []), isNull);
    },
  );

  test('a swing day takes one for the warmest hours too, if there is one', () {
    final coolOnly = _own('a', bands: {WarmthBand.cool});
    final both = _own('b', bands: {WarmthBand.cool, WarmthBand.warm});
    final day = _swing(WarmthBand.cool, WarmthBand.warm);
    expect(choose([coolOnly, both], day: day)?.id, 'b');
    // None spans the day: the coldest hours decide.
    expect(choose([coolOnly], day: day)?.id, 'a');
  });

  test('on a wet day, one for rain comes first', () {
    final outfits = [_own('a'), _own('b', rain: true)];
    expect(
      choose(outfits, day: bandsFor(WarmthBand.mild, rain: true))?.id,
      'b',
    );
  });

  test('a different one each day, and tomorrow not today’s', () {
    final outfits = [_own('a'), _own('b'), _own('c')];
    final week = [
      for (var day = 0; day < 6; day++)
        choose(outfits, date: _date.add(Duration(days: day)))!.id,
    ];
    expect(week.toSet(), {'a', 'b', 'c'});
    final today = choose(outfits)!;
    final tomorrow = choose(
      outfits,
      date: _date.add(const Duration(days: 1)),
      avoid: today.id,
    )!;
    expect(tomorrow.id, isNot(today.id));
    // With only one, tomorrow may repeat it.
    expect(choose([today], avoid: today.id), today);
  });
}
