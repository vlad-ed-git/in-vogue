import 'package:equatable/equatable.dart';
import 'package:in_vogue/features/weather/domain/entities/hourly_weather.dart';

/// The hourly forecast for a place, in its local time.
class Forecast extends Equatable {
  const Forecast({
    required this.hours,
    required this.utcOffset,
    required this.fetchedAt,
  });

  /// In time order.
  final List<HourlyWeather> hours;

  /// The place's offset from UTC.
  final Duration utcOffset;

  /// When the forecast was fetched, in UTC.
  final DateTime fetchedAt;

  /// The place's wall-clock time at the instant [now], held in UTC.
  DateTime localTime(DateTime now) => now.toUtc().add(utcOffset);

  @override
  List<Object?> get props => [hours, utcOffset, fetchedAt];
}
