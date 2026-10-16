import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

abstract interface class PicksRepository {
  /// Ids of the loved colourways.
  Future<Either<Failure, Set<String>>> picks();

  /// Loves or unloves a colourway; returns every pick after the change.
  Future<Either<Failure, Set<String>>> setPick(
    String colourwayId, {
    required bool loved,
  });
}
