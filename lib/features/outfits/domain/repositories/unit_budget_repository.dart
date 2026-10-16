import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

/// The try-on units the app may spend.
abstract interface class UnitBudgetRepository {
  /// Reserves [units] before a try-on call. A [TryOnFailure] with
  /// [TryOnProblem.budgetSpent] when they would pass the limit.
  Future<Either<Failure, Unit>> reserve(int units);

  /// Gives back [units] reserved for a call the service did not charge.
  Future<Either<Failure, Unit>> release(int units);
}
