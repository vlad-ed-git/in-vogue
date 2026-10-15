import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/tried_on_outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';

/// The try-on before its service exists: every try-on fails, so no picture
/// is ever shown as the person's that is not.
class UnavailableTryOnRepository implements TryOnRepository {
  const UnavailableTryOnRepository();

  @override
  Future<Either<Failure, TriedOnOutfit>> tryOn({
    required UserPhoto photo,
    required DayWeather weather,
  }) async => const Left(ServerFailure());
}
