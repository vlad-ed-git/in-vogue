import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';

/// The curated outfit catalog, kept on the phone until its version changes.
abstract interface class OutfitCatalogRepository {
  /// The onboarding sample, in catalog order. Anyone may read it.
  Future<Either<Failure, List<CatalogOutfit>>> sample();

  /// Every outfit, in catalog order. Needs a signed-in person.
  Future<Either<Failure, List<CatalogOutfit>>> outfits();
}
