import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/services/choose_outfit.dart';

Outfit _outfit(String id, List<String> pieces) => Outfit(
  id: id,
  signature: pieces.join('+'),
  pieces: pieces,
  passes: const [],
);

final _ranked = [
  _outfit('a', ['p1', 'p2']),
  _outfit('b', ['p3', 'p4']),
  _outfit('c', ['p5', 'p6']),
  _outfit('d', ['p7', 'p8']),
  _outfit('e', ['p9', 'p10']),
];

String? _choose({
  Map<String, DateTime?> suggested = const {},
  Set<String> picks = const {},
  Set<String> refused = const {},
}) => ChooseOutfit.from(
  _ranked,
  suggested: suggested,
  picks: picks,
  refused: refused,
)?.id;

void main() {
  test('takes the best outfit never suggested', () {
    expect(_choose(), 'a');
    expect(_choose(suggested: {'p1+p2': DateTime.utc(2026, 10, 1)}), 'b');
  });

  test('lets loved pieces lift an outfit, by up to a quarter of the list', () {
    // Each place is worth 0.8 / 5; a fully loved outfit gains 0.2.
    expect(_choose(picks: {'p3', 'p4'}), 'b');
    expect(_choose(picks: {'p5', 'p6'}), 'a');
    expect(_choose(picks: {'p3'}), 'a');
  });

  test('never rules out an outfit without loved pieces', () {
    expect(
      _choose(
        suggested: {'p5+p6': DateTime.utc(2026, 10, 1)},
        picks: {'p5', 'p6', 'unknown'},
      ),
      'a',
    );
  });

  test('once every outfit was suggested, takes the one suggested longest '
      'ago, a time still being written counting as now', () {
    final all = {
      for (final (index, outfit) in _ranked.indexed)
        outfit.signature: DateTime.utc(2026, 10, 10 - index),
    };
    expect(_choose(suggested: all), 'e');
    expect(_choose(suggested: {...all, 'p9+p10': null}), 'd');
  });

  test('breaks a tie in time by the score', () {
    final same = DateTime.utc(2026, 10, 1);
    expect(
      _choose(
        suggested: {for (final outfit in _ranked) outfit.signature: same},
        picks: {'p3', 'p4'},
      ),
      'b',
    );
  });

  test('never takes an outfit with a piece whose photo was refused', () {
    expect(_choose(refused: {'p2'}), 'b');
    expect(_choose(refused: {'p2'}, picks: {'p1', 'p2'}), 'b');
    final all = {
      for (final (index, outfit) in _ranked.indexed)
        outfit.signature: DateTime.utc(2026, 10, 10 - index),
    };
    expect(_choose(suggested: all, refused: {'p10'}), 'd');
  });

  test('has nothing when there is nothing to choose from, or every outfit '
      'has a refused piece', () {
    expect(
      ChooseOutfit.from(
        const [],
        suggested: const {},
        picks: const {},
        refused: const {},
      ),
      isNull,
    );
    expect(_choose(refused: {'p1', 'p3', 'p5', 'p7', 'p9'}), isNull);
  });
}
