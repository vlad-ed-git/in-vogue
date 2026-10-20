import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/preferences/domain/repositories/preferences_repository.dart';

/// The occasion the person chose for each date, from today on.
class GetOccasions implements UseCase<Map<DateTime, Occasion>, NoParams> {
  const GetOccasions(this._repository);
  final PreferencesRepository _repository;

  @override
  Future<Either<Failure, Map<DateTime, Occasion>>> call(NoParams params) =>
      _repository.occasions();
}
