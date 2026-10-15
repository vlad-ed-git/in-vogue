import 'package:dio/dio.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

abstract interface class WeatherRemoteDataSource {
  /// Open-Meteo's hourly forecast JSON for three days, in local time.
  /// Throws [NetworkException] or [ServerException].
  Future<Map<String, Object?>> fetchForecast({
    required double latitude,
    required double longitude,
  });
}

/// Open-Meteo's forecast API: free, keyless, for noncommercial use.
class WeatherRemoteDataSourceImpl implements WeatherRemoteDataSource {
  WeatherRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  static const baseUrl = 'https://api.open-meteo.com/v1';

  /// Fields the weather rules read.
  static const hourlyFields = [
    'temperature_2m',
    'apparent_temperature',
    'precipitation_probability',
    'precipitation',
    'snowfall',
    'weather_code',
    'wind_gusts_10m',
  ];

  @override
  Future<Map<String, Object?>> fetchForecast({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio.get<Object?>(
        '/forecast',
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'timezone': 'auto',
          'forecast_days': 3,
          'hourly': hourlyFields.join(','),
        },
      );
      final data = response.data;
      if (data is Map<String, Object?>) return data;
      throw ServerException(
        const FormatException('The forecast is not a JSON object'),
        StackTrace.current,
      );
    } on DioException catch (error, stack) {
      throw switch (error.type) {
        DioExceptionType.connectionError ||
        DioExceptionType.connectionTimeout ||
        DioExceptionType.sendTimeout ||
        DioExceptionType.receiveTimeout => NetworkException(error, stack),
        _ => ServerException(error, stack),
      };
    }
  }
}
