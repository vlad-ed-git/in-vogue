import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';

/// The profile kept on the phone.
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._local);
  final ProfileLocalDataSource _local;

  @override
  Future<Either<Failure, String?>> name() async {
    try {
      return Right(_local.name());
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, String>> saveName(String name) async {
    final trimmed = name.trim();
    try {
      await _local.saveName(trimmed);
      return Right(trimmed);
    } on CacheException {
      return const Left(CacheFailure());
    }
  }
}
