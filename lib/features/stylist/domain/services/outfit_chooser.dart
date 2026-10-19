import 'package:in_vogue/features/stylist/domain/services/outfit_scorer.dart';

/// The owner's rule for choosing among the scored candidates (design §7.5).
abstract final class OutfitChooser {
  /// The share of the day's best score an outfit needs to be chosen.
  static const acceptable = 0.85;

  /// Among the outfits within 15% of the day's best score, the best one
  /// never suggested; when every one was, the one suggested longest ago.
  /// Ties go to the higher score, then to the lower id. Null when there is
  /// nothing to choose from.
  static OutfitScore? choose(
    List<OutfitScore> scores, {
    Map<String, DateTime> suggestedAt = const {},
  }) {
    final shortlist = shortlistOf(scores);
    if (shortlist.isEmpty) return null;
    int byScore(OutfitScore a, OutfitScore b) {
      final total = b.total.compareTo(a.total);
      return total != 0 ? total : a.outfit.id.compareTo(b.outfit.id);
    }

    final fresh = [
      for (final score in shortlist)
        if (!suggestedAt.containsKey(score.outfit.id)) score,
    ];
    if (fresh.isNotEmpty) return (fresh..sort(byScore)).first;
    return (shortlist..sort((a, b) {
          final when = suggestedAt[a.outfit.id]!.compareTo(
            suggestedAt[b.outfit.id]!,
          );
          return when != 0 ? when : byScore(a, b);
        }))
        .first;
  }

  /// The outfits within 15% of the day's best score.
  static List<OutfitScore> shortlistOf(List<OutfitScore> scores) {
    if (scores.isEmpty) return const [];
    final best = scores
        .map((score) => score.total)
        .reduce((a, b) => a > b ? a : b);
    final shortlist = [
      for (final score in scores)
        if (score.total >= best * acceptable) score,
    ];
    return shortlist;
  }
}
