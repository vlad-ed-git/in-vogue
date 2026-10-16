import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';

class MakeupLookParams extends Equatable {
  const MakeupLookParams({
    required this.accountId,
    required this.outfitSignature,
  });

  final String accountId;
  final String outfitSignature;

  @override
  List<Object?> get props => [accountId, outfitSignature];
}

/// The look made for an outfit; null when none was.
class GetMakeupLook implements UseCase<MakeupLook?, MakeupLookParams> {
  const GetMakeupLook(this._repository);
  final MakeupRepository _repository;

  @override
  Future<Either<Failure, MakeupLook?>> call(MakeupLookParams params) =>
      _repository.look(params.accountId, params.outfitSignature);
}
