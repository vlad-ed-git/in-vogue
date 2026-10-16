import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// The knowledge base's outfits and the ones each account has been shown.
abstract interface class OutfitRepository {
  /// The outfits for the knowledge-base [cell], best first.
  Future<Either<Failure, List<Outfit>>> outfitsFor(String cell);

  /// The outfit [id]; null when the knowledge base has none.
  Future<Either<Failure, Outfit?>> outfit(String id);

  /// Signatures of every outfit made for [accountId].
  Future<Either<Failure, Set<String>>> shownSignatures(String accountId);

  /// The outfit made for [accountId] on [date] for [occasion], with its
  /// picture on the phone; null when none was made.
  Future<Either<Failure, DayOutfit?>> dayOutfit(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  });

  /// Keeps [picture] of [outfit] on the account and the phone, and records
  /// the outfit as made for [date] and [occasion], so it is never chosen
  /// again.
  Future<Either<Failure, DayOutfit>> record(
    String accountId, {
    required Outfit outfit,
    required String cell,
    required DateTime date,
    required Occasion occasion,
    required List<int> picture,
  });
}
