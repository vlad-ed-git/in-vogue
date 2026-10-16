import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/catalog/data/data_sources/picks_local_data_source.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';

/// Picks kept on the phone.
class PicksRepositoryImpl implements PicksRepository {
  PicksRepositoryImpl(this._local);
  final PicksLocalDataSource _local;

  @override
  Future<Either<Failure, Set<String>>> picks() async {
    try {
      return Right(_local.picks());
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Set<String>>> setPick(
    String colourwayId, {
    required bool loved,
  }) async {
    try {
      final picks = {..._local.picks()};
      loved ? picks.add(colourwayId) : picks.remove(colourwayId);
      await _local.save(picks);
      return Right(picks);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
