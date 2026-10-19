import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';

/// What the person did that the taste model learns from, kept on the phone
/// and saved on the account.
abstract interface class TasteRepository {
  /// The signals kept on this phone.
  Future<Either<Failure, List<TasteSignal>>> signals();

  /// Keeps [signal] on this phone.
  Future<Either<Failure, Unit>> keep(TasteSignal signal);

  /// Adds [accountId]'s signals to the phone's.
  Future<Either<Failure, Unit>> restore(String accountId);

  /// Saves the phone's signals on [accountId]'s account, beside the ones
  /// already there.
  Future<Either<Failure, Unit>> save(String accountId);

  /// Forgets the phone's signals; the account keeps its own.
  Future<Either<Failure, Unit>> clear();
}
