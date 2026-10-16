import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_job.dart';

/// Makeup jobs kept on the phone until their look is recorded.
abstract interface class MakeupJobRepository {
  /// The job [key]; null when there is none.
  Future<Either<Failure, MakeupJob?>> job(String key);

  Future<Either<Failure, Unit>> save(MakeupJob job);

  Future<Either<Failure, Unit>> clear(String key);

  /// Forgets every job of [accountId].
  Future<Either<Failure, Unit>> clearAccount(String accountId);
}
