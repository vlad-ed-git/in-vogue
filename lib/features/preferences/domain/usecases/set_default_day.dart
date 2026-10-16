import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/preferences/domain/repositories/preferences_repository.dart';

/// Chooses the day Home opens on.
class SetDefaultDay implements UseCase<ForecastDay, ForecastDay> {
  const SetDefaultDay(this._repository);
  final PreferencesRepository _repository;

  @override
  Future<Either<Failure, ForecastDay>> call(ForecastDay day) =>
      _repository.setDefaultDay(day);
}
