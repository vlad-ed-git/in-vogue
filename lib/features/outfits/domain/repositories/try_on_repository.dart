import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/tried_on_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';

abstract interface class TryOnRepository {
  /// Picks an unseen outfit for [weather] and dresses [photo] in it.
  Future<Either<Failure, TriedOnOutfit>> tryOn({
    required UserPhoto photo,
    required DayWeather weather,
  });
}
