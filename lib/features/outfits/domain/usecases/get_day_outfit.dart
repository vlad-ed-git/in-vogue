import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';

class DayOutfitParams extends Equatable {
  const DayOutfitParams({
    required this.accountId,
    required this.date,
    required this.occasion,
  });

  final String accountId;

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  @override
  List<Object?> get props => [accountId, date, occasion];
}

/// The outfit already made for a day and occasion; null when none was.
class GetDayOutfit implements UseCase<DayOutfit?, DayOutfitParams> {
  const GetDayOutfit(this._repository);
  final OutfitRepository _repository;

  @override
  Future<Either<Failure, DayOutfit?>> call(DayOutfitParams params) =>
      _repository.dayOutfit(
        params.accountId,
        date: params.date,
        occasion: params.occasion,
      );
}
