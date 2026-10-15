import 'package:equatable/equatable.dart';

/// One forecast hour. Amounts and gusts cover the hour before [time].
class HourlyWeather extends Equatable {
  const HourlyWeather({
    required this.time,
    required this.temperature,
    required this.feelsLike,
    required this.precipitationProbability,
    required this.precipitation,
    required this.snowfall,
    required this.weatherCode,
    required this.windGusts,
  });

  /// Local wall-clock time at the forecast's place, held in UTC so that no
  /// device time zone can shift it.
  final DateTime time;

  /// °C.
  final double temperature;

  /// Apparent temperature, °C.
  final double feelsLike;

  /// Percent.
  final int precipitationProbability;

  /// Rain, showers and snow, in millimetres.
  final double precipitation;

  /// Centimetres.
  final double snowfall;

  /// WMO weather interpretation code.
  final int weatherCode;

  /// Strongest gust, km/h.
  final double windGusts;

  HourlyWeather copyWith({
    double? temperature,
    double? feelsLike,
    int? precipitationProbability,
    double? precipitation,
    double? snowfall,
    int? weatherCode,
    double? windGusts,
  }) => HourlyWeather(
    time: time,
    temperature: temperature ?? this.temperature,
    feelsLike: feelsLike ?? this.feelsLike,
    precipitationProbability:
        precipitationProbability ?? this.precipitationProbability,
    precipitation: precipitation ?? this.precipitation,
    snowfall: snowfall ?? this.snowfall,
    weatherCode: weatherCode ?? this.weatherCode,
    windGusts: windGusts ?? this.windGusts,
  );

  @override
  List<Object?> get props => [
    time,
    temperature,
    feelsLike,
    precipitationProbability,
    precipitation,
    snowfall,
    weatherCode,
    windGusts,
  ];
}
