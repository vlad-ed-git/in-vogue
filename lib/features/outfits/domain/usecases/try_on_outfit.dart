import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/outfits/domain/entities/tried_on_outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';

class TryOnParams extends Equatable {
  const TryOnParams({required this.photo, required this.weather});

  final UserPhoto photo;
  final DayWeather weather;

  @override
  List<Object?> get props => [photo, weather];
}

/// Dresses the person in an outfit picked for a day's weather and occasion.
class TryOnOutfit implements UseCase<TriedOnOutfit, TryOnParams> {
  const TryOnOutfit(this._repository);
  final TryOnRepository _repository;

  @override
  Future<Either<Failure, TriedOnOutfit>> call(TryOnParams params) =>
      _repository.tryOn(photo: params.photo, weather: params.weather);
}
