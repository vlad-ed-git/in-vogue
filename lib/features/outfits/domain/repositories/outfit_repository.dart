import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';

/// The knowledge base's outfits.
abstract interface class OutfitRepository {
  /// The outfits for the knowledge-base [cell], best first.
  Future<Either<Failure, List<Outfit>>> outfitsFor(String cell);

  /// The outfit [id]; null when the knowledge base has none.
  Future<Either<Failure, Outfit?>> outfit(String id);
}
