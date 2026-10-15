import 'package:dartz/dartz.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';

abstract interface class WeatherRepository {
  /// How long a forecast is used before it is fetched again.
  static const freshFor = Duration(hours: 1);

  /// The forecast for [location]: a new one when the network allows, the
  /// kept one otherwise.
  Future<Either<Failure, Forecast>> forecastFor(UserLocation location);
}
