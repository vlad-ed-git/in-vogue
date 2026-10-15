import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';

/// The weather line for the day on screen.
class WeatherReport extends Equatable {
  const WeatherReport({
    required this.day,
    required this.weather,
    required this.fetchedAt,
    required this.isSaved,
  });

  final ForecastDay day;

  /// Holds the date and the occasion it was read for.
  final DayWeather weather;

  /// When the forecast was fetched, in UTC.
  final DateTime fetchedAt;

  /// Whether a new forecast could not be fetched and this one is older.
  final bool isSaved;

  @override
  List<Object?> get props => [day, weather, fetchedAt, isSaved];
}
