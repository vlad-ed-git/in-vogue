import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_job_local_data_source.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_job.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_job_repository.dart';

class MakeupJobRepositoryImpl implements MakeupJobRepository {
  MakeupJobRepositoryImpl(this._local);
  final MakeupJobLocalDataSource _local;

  @override
  Future<Either<Failure, MakeupJob?>> job(String key) async {
    try {
      return Right(_local.jobs()[key]);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> save(MakeupJob job) async {
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
