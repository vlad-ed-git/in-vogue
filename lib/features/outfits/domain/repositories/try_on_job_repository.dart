import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// Try-on jobs kept on the phone until their outfit is recorded.
abstract interface class TryOnJobRepository {
  /// The job [key]; null when there is none.
  Future<Either<Failure, TryOnJob?>> job(String key);

  Future<Either<Failure, Unit>> save(TryOnJob job);

  Future<Either<Failure, Unit>> clear(String key);

  /// Forgets every job of [accountId].
  Future<Either<Failure, Unit>> clearAccount(String accountId);
}
