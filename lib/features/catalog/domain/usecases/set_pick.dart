import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';

class SetPickParams extends Equatable {
  const SetPickParams(this.colourwayId, {required this.loved});

  final String colourwayId;
  final bool loved;

  @override
  List<Object?> get props => [colourwayId, loved];
}

/// Loves or unloves a colourway; returns every pick after the change.
class SetPick implements UseCase<Set<String>, SetPickParams> {
  const SetPick(this._repository);
  final PicksRepository _repository;

  @override
  Future<Either<Failure, Set<String>>> call(SetPickParams params) =>
      _repository.setPick(params.colourwayId, loved: params.loved);
}
