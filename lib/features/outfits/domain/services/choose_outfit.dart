import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// Chooses an outfit, preferring one never suggested to the person.
abstract final class ChooseOutfit {
  /// Weight of an outfit's place in the knowledge base's ranking, which
  /// orders a cell's outfits by weather, occasion and colour.
  static const rankWeight = 0.8;

  /// Weight of the share of its pieces the person loves.
  static const picksWeight = 0.2;

  /// The best of [ranked] (best first) never [suggested]: loved pieces in
  /// [picks] lift an outfit, but never rule one out. An outfit with a piece
  /// in [refused] is never taken. When every other outfit was suggested,
  /// the one suggested longest ago; a time still being written counts as
  /// now. Null when there is none to take.
  static Outfit? from(
    List<Outfit> ranked, {
    required Map<String, DateTime?> suggested,
    required Set<String> picks,
    required Set<String> refused,
  }) {
    final scored = [
      for (final (index, outfit) in ranked.indexed)
        if (!outfit.pieces.any(refused.contains))
          (outfit: outfit, score: _score(outfit, index, ranked.length, picks)),
    ];
    if (scored.isEmpty) return null;
    final fresh = [
      for (final option in scored)
        if (!suggested.containsKey(option.outfit.signature)) option,
    ];
    if (fresh.isNotEmpty) {
      return fresh.reduce((a, b) => b.score > a.score ? b : a).outfit;
    }
    final now = DateTime.utc(9999);
    DateTime last(Outfit outfit) => suggested[outfit.signature] ?? now;
    return scored.reduce((a, b) {
      final (lastA, lastB) = (last(a.outfit), last(b.outfit));
      final earlier =
          lastB.isBefore(lastA) || (lastB == lastA && b.score > a.score);
      return earlier ? b : a;
    }).outfit;
  }

  static double _score(Outfit outfit, int index, int count, Set<String> picks) {
    final loved = outfit.pieces.isEmpty
        ? 0.0
        : outfit.pieces.where(picks.contains).length / outfit.pieces.length;
    return rankWeight * (1 - index / count) + picksWeight * loved;
  }
}
