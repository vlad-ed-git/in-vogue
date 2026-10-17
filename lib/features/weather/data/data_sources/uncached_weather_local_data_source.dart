import 'package:in_vogue/features/weather/data/data_sources/weather_local_data_source.dart';

/// Keeps no forecast: for the widget's background refresh, which never
/// opens the app's cache.
class UncachedWeatherLocalDataSource implements WeatherLocalDataSource {
  const UncachedWeatherLocalDataSource();

  @override
  Future<SavedForecast?> read({
    required String key,
    required DateTime now,
  }) async => null;

  @override
  Future<void> save({
    required String key,
    required Map<String, Object?> json,
    required DateTime fetchedAt,
  }) async {}
}
