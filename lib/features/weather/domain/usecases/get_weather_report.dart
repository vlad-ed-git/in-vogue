import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/usecases/use_case.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/repositories/weather_repository.dart';
import 'package:in_vogue/features/weather/domain/services/day_weather_rules.dart';

class WeatherReportParams extends Equatable {
  const WeatherReportParams({required this.location, this.day, this.occasion});

  final UserLocation location;

  /// The day shown at the place's local time when null.
  final ForecastDay? day;

  /// The day's default occasion when null.
  final Occasion? occasion;

  @override
  List<Object?> get props => [location, day, occasion];
}

class GetWeatherReport implements UseCase<WeatherReport, WeatherReportParams> {
  const GetWeatherReport(this._repository);

  final WeatherRepository _repository;

  @override
  Future<Either<Failure, WeatherReport>> call(
    WeatherReportParams params,
  ) async {
    final result = await _repository.forecastFor(params.location);
    return result.flatMap((forecast) {
      final now = clock.now();
      final local = forecast.localTime(now);
      final day = params.day ?? ForecastDay.shownAt(local);
      final date = day.dateFrom(local);
      final occasion = params.occasion ?? Occasion.defaultFor(date);
      final weather = DayWeatherRules.summarize(
        forecast,
        date: date,
        occasion: occasion,
      );
      final weatherClass = DayWeatherRules.classify(
        forecast,
        date: date,
        occasion: occasion,
      );
      if (weather == null || weatherClass == null) {
        return const Left(ServerFailure());
      }
      return Right(
        WeatherReport(
          day: day,
          weather: weather,
          weatherClass: weatherClass,
          fetchedAt: forecast.fetchedAt,
          isSaved:
              now.toUtc().difference(forecast.fetchedAt) >=
              WeatherRepository.freshFor,
        ),
      );
    });
  }
}
