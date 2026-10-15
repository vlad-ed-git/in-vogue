import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/entities/hourly_weather.dart';

/// Reads Open-Meteo's hourly forecast JSON.
abstract final class OpenMeteoForecastModel {
  /// Hours without a temperature, feels-like or weather code are skipped;
  /// missing amounts, chances and gusts count as none.
  ///
  /// Throws [FormatException] when [json] is not an hourly forecast.
  static Forecast fromJson(Object? json, {required DateTime fetchedAt}) {
    if (json case {
      'utc_offset_seconds': final int offsetSeconds,
      'hourly': {
        'time': final List<Object?> times,
        'temperature_2m': final List<Object?> temperatures,
        'apparent_temperature': final List<Object?> feelsLike,
        'precipitation_probability': final List<Object?> chances,
        'precipitation': final List<Object?> amounts,
        'snowfall': final List<Object?> snowfall,
        'weather_code': final List<Object?> codes,
        'wind_gusts_10m': final List<Object?> gusts,
      },
    }) {
      final columns = [
        temperatures,
        feelsLike,
        chances,
        amounts,
        snowfall,
        codes,
        gusts,
      ];
      if (columns.any((column) => column.length != times.length)) {
        throw const FormatException('Hourly lists differ in length');
      }
      return Forecast(
        hours: [
          for (var i = 0; i < times.length; i++)
            if (temperatures[i] is num &&
                feelsLike[i] is num &&
                codes[i] is num)
              HourlyWeather(
                time: _wallClock(times[i]),
                temperature: (temperatures[i]! as num).toDouble(),
                feelsLike: (feelsLike[i]! as num).toDouble(),
                precipitationProbability: _number(chances[i]).round(),
                precipitation: _number(amounts[i]),
                snowfall: _number(snowfall[i]),
                weatherCode: (codes[i]! as num).toInt(),
                windGusts: _number(gusts[i]),
              ),
        ],
        utcOffset: Duration(seconds: offsetSeconds),
        fetchedAt: fetchedAt,
      );
    }
    throw const FormatException('Not an hourly forecast');
  }

  /// "2026-10-16T15:00" as the same wall-clock time held in UTC.
  static DateTime _wallClock(Object? time) {
    if (time is! String) throw const FormatException('Hour without a time');
    return DateTime.parse('${time}Z');
  }

  static double _number(Object? value) => value is num ? value.toDouble() : 0;
}
