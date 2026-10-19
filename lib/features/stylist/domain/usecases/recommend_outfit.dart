import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/domain/services/candidate_rules.dart';
import 'package:in_vogue/features/stylist/domain/services/outfit_chooser.dart';
import 'package:in_vogue/features/stylist/domain/services/outfit_scorer.dart';
import 'package:in_vogue/features/stylist/domain/services/reason_rules.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';

class RecommendParams extends Equatable {
  const RecommendParams({
    required this.day,
    required this.date,
    required this.occasion,
    this.season,
    this.refused = const {},
    this.history = const OutfitHistory(),
  });

  final DayBands day;

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  /// The person's colour season from a clear reading; null without one.
  final ColourSeason? season;

  /// Colourway ids whose photos the try-on refused.
  final Set<String> refused;
  final OutfitHistory history;

  @override
  List<Object?> get props => [day, date, occasion, season, refused, history];
}

/// The catalog outfit for a day and an occasion (design §7): those that
/// suit the person's colours in the day's coldest hours, filtered by the
/// occasion, the warmest hours, rain and snow, scored, and chosen by the
/// owner's rule. Null when the catalog has none for the day.
class RecommendOutfit implements UseCase<Recommendation?, RecommendParams> {
  const RecommendOutfit(this._catalog, {this.scorer = const OutfitScorer()});

  final OutfitCatalogRepository _catalog;
  final OutfitScorer scorer;

  @override
  Future<Either<Failure, Recommendation?>> call(RecommendParams params) async {
    final outfits = await _catalog.outfits();
    return outfits.map((outfits) => choose(outfits, params));
  }

  /// The choice among [outfits], the catalog in order.
  Recommendation? choose(List<CatalogOutfit> outfits, RecommendParams params) {
    final day = params.day;
    final (outfits: candidates, :relaxed) = CandidateRules.of(
      outfits.where(
        (outfit) => CandidateRules.fits(outfit, day, params.season),
      ),
      day: day,
      occasion: params.occasion,
      refused: params.refused,
    );
    final scores = scorer.score(
      candidates,
      day: day,
      occasion: params.occasion,
      date: params.date,
      history: params.history,
    );
    final chosen = OutfitChooser.choose(
      scores,
      suggestedAt: params.history.suggestedAt,
    );
    if (chosen == null) return null;
    return Recommendation(
      outfit: chosen.outfit,
      reason: ReasonRules.of(
        chosen.outfit,
        day: day,
        relaxed: relaxed,
        season: params.season,
      ),
      score: chosen.total,
      candidates: candidates.length,
      shortlist: OutfitChooser.shortlistOf(scores).length,
      relaxed: relaxed,
    );
  }
}
