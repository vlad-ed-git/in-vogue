import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// Chooses an outfit no one has shown the person yet.
abstract final class ChooseOutfit {
  /// Weight of an outfit's place in the knowledge base's ranking, which
  /// orders a cell's outfits by weather, occasion and colour.
  static const rankWeight = 0.8;

  /// Weight of the share of its pieces the person loves.
  static const picksWeight = 0.2;

  /// The best of [ranked] (best first) whose signature is not in [shown]:
  /// loved pieces in [picks] lift an outfit, but never rule one out. Null
  /// when every outfit has been shown.
  static Outfit? from(
    List<Outfit> ranked, {
    required Set<String> shown,
    required Set<String> picks,
  }) {
    Outfit? best;
    var bestScore = double.negativeInfinity;
    for (var index = 0; index < ranked.length; index++) {
      final outfit = ranked[index];
      if (shown.contains(outfit.signature)) continue;
      final loved = outfit.pieces.isEmpty
          ? 0.0
          : outfit.pieces.where(picks.contains).length / outfit.pieces.length;
      final score =
          rankWeight * (1 - index / ranked.length) + picksWeight * loved;
      if (score > bestScore) {
        best = outfit;
        bestScore = score;
      }
    }
    return best;
  }
}
