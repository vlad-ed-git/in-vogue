import 'package:in_vogue/features/weather/data/data_sources/weather_local_data_source.dart';

/// Successful forecasts shared by all dates in one background run.
class MemoryWeatherLocalDataSource implements WeatherLocalDataSource {
  final _forecasts = <String, SavedForecast>{};

  @override
  Future<SavedForecast?> read({
    required String key,
    required DateTime now,
  }) async => _forecasts[key];

  @override
  Future<void> save({
    required String key,
    required Map<String, Object?> json,
    required DateTime fetchedAt,
  }) async {
    _forecasts[key] = (json: json, fetchedAt: fetchedAt);
  }
}
