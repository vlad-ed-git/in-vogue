import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/entities/hourly_weather.dart';

/// 15 to 17 October 2026, hourly, in local wall-clock time.
final forecastStart = DateTime.utc(2026, 10, 15);

/// When [forecastWith] forecasts are fetched.
final forecastFetchedAt = DateTime.utc(2026, 10, 15, 19);

/// A dry, calm, 15° forecast for three days, with [overrides] applied to
/// hours of 16 October by hour of day.
Forecast forecastWith(
  Map<int, HourlyWeather Function(HourlyWeather hour)> overrides,
) => Forecast(
  hours: [
    for (var index = 0; index < 72; index++)
      () {
        final time = forecastStart.add(Duration(hours: index));
        final hour = HourlyWeather(
          time: time,
          temperature: 15,
          feelsLike: 15,
          precipitationProbability: 0,
          precipitation: 0,
          snowfall: 0,
          weatherCode: 0,
          windGusts: 10,
        );
        final override = time.day == 16 ? overrides[time.hour] : null;
        return override == null ? hour : override(hour);
      }(),
  ],
  utcOffset: const Duration(hours: -4),
  fetchedAt: forecastFetchedAt,
);
