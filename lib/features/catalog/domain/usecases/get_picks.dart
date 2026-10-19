import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';

/// Ids of the loved outfits.
class GetPicks implements UseCase<Set<String>, NoParams> {
  const GetPicks(this._repository);
  final PicksRepository _repository;

  @override
  Future<Either<Failure, Set<String>>> call(NoParams params) =>
      _repository.picks();
}
