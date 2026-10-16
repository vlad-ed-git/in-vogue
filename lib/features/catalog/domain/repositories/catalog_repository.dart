import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';

abstract interface class CatalogRepository {
  /// Every piece of the partner's collection, in catalog order.
  Future<Either<Failure, List<Piece>>> pieces();
}
