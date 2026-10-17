import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

abstract interface class PicksRepository {
  /// Ids of the loved colourways.
  Future<Either<Failure, Set<String>>> picks();

  /// Forgets every pick, and which ones an account holds.
  Future<Either<Failure, Unit>> clear();

  /// The picks this phone last saved on [accountId]'s account.
  Future<Either<Failure, Set<String>>> synced(String accountId);

  /// Records [picks] as saved on [accountId]'s account.
  Future<Either<Failure, Unit>> markSynced(String accountId, Set<String> picks);

  /// Loves every one of [colourwayIds]; returns every pick after.
  Future<Either<Failure, Set<String>>> addPicks(Set<String> colourwayIds);

  /// Loves or unloves a colourway; returns every pick after the change.
  Future<Either<Failure, Set<String>>> setPick(
    String colourwayId, {
    required bool loved,
  });
}
