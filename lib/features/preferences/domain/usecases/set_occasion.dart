import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/preferences/domain/repositories/preferences_repository.dart';

class SetOccasionParams extends Equatable {
  const SetOccasionParams({required this.date, required this.occasion});

  /// Midnight UTC of the local date.
  final DateTime date;
  final Occasion occasion;

  @override
  List<Object?> get props => [date, occasion];
}

/// Keeps the occasion the person chose for a date.
class SetOccasion implements UseCase<Unit, SetOccasionParams> {
  const SetOccasion(this._repository);
  final PreferencesRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(SetOccasionParams params) =>
      _repository.setOccasion(params.date, params.occasion);
}
