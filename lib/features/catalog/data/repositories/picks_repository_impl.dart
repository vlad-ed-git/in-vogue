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
  Future<Either<Failure, Unit>> clear() async {
    try {
      await _local.save(const {});
      await _local.forgetSynced();
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Set<String>>> addPicks(
    Set<String> outfitIds,
  ) async {
    try {
      final picks = {..._local.picks(), ...outfitIds};
      await _local.save(picks);
      return Right(picks);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Set<String>>> removePicks(
    Set<String> outfitIds,
  ) async {
    try {
      final picks = _local.picks().difference(outfitIds);
      await _local.save(picks);
      return Right(picks);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Set<String>>> synced(String accountId) async {
    try {
      return Right(_local.synced(accountId));
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> markSynced(
    String accountId,
    Set<String> picks,
  ) async {
    try {
      await _local.saveSynced(accountId, picks);
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Set<String>>> setPick(
    String outfitId, {
    required bool loved,
  }) async {
    try {
      final picks = {..._local.picks()};
      loved ? picks.add(outfitId) : picks.remove(outfitId);
      await _local.save(picks);
      return Right(picks);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
