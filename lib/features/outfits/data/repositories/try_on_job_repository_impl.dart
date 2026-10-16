import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';

class TryOnJobRepositoryImpl implements TryOnJobRepository {
  TryOnJobRepositoryImpl(this._local);
  final TryOnJobLocalDataSource _local;

  @override
  Future<Either<Failure, TryOnJob?>> job(String key) async {
    try {
      return Right(_local.jobs()[key]);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> save(TryOnJob job) async {
    try {
      await _local.save({..._local.jobs(), job.key: job});
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> clearAccount(String accountId) async {
    try {
      await _local.save({
        for (final MapEntry(:key, :value) in _local.jobs().entries)
          if (value.accountId != accountId) key: value,
      });
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> clear(String key) async {
    try {
      await _local.save({..._local.jobs()}..remove(key));
      return const Right(unit);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
