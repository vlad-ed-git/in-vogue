import 'dart:convert';
import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/directory_key_value_store.dart';
import 'package:in_vogue/features/outfits/data/models/try_on_job_model.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_job_repository.dart';
import 'package:path/path.dart' as path;

/// Atomic job files shared by foreground and background engines.
class SharedTryOnJobRepository implements TryOnJobRepository {
  const SharedTryOnJobRepository(this.jobsDirectory, {this.legacy});
  final String jobsDirectory;
  final TryOnJobRepository? legacy;

  DirectoryKeyValueStore _store(String account) =>
      DirectoryKeyValueStore(path.join(jobsDirectory, account));

  static String _account(String key) => key.split('|').first;

  @override
  Future<Either<Failure, TryOnJob?>> job(String key) async {
    try {
      final saved = _store(_account(key)).readString(key);
      if (saved != null) {
        try {
          return Right(TryOnJobModel.fromJson(jsonDecode(saved)));
        } on FormatException {
          // Unreadable progress is retried rather than cached as a failure.
        }
      }
      final old =
          await legacy?.job(key) ?? const Right<Failure, TryOnJob?>(null);
      if (old case Right(value: final job?)) {
        final kept = await save(job);
        if (kept case Left(value: final failure)) return Left(failure);
      }
      return old;
    } on CacheException {
      return const Left(CacheFailure());
    }
  }

  @override
  Future<Either<Failure, Unit>> save(TryOnJob job) => _guard(() async {
    await _store(job.accountId)
        .writeString(job.key, jsonEncode(TryOnJobModel.toJson(job)));
    return await legacy?.clear(job.key) ?? const Right(unit);
  });

  @override
  Future<Either<Failure, Unit>> clear(String key) => _guard(() async {
    await _store(_account(key)).delete(key);
    return await legacy?.clear(key) ?? const Right(unit);
  });

  @override
  Future<Either<Failure, Unit>> clearAccount(String accountId) =>
      _guard(() async {
        final directory = Directory(_store(accountId).directory);
        if (directory.existsSync()) await directory.delete(recursive: true);
        return await legacy?.clearAccount(accountId) ?? const Right(unit);
      });

  Future<Either<Failure, Unit>> _guard(
    Future<Either<Failure, Unit>> Function() action,
  ) async {
    try {
      return await action();
    } on CacheException {
      return const Left(CacheFailure());
    } on FileSystemException {
      return const Left(CacheFailure());
    }
  }
}
