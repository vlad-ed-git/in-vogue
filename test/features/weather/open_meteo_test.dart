import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:in_vogue/features/weather/data/models/open_meteo_forecast_model.dart';

/// An Open-Meteo answer for [hours] hours from 15 October 2026, 00:00.
Map<String, Object?> openMeteoJson({int hours = 48}) => {
  'latitude': 40.71,
  'longitude': -74.01,
  'utc_offset_seconds': -14400,
  'timezone': 'America/New_York',
  'hourly': {
    'time': [
      for (var i = 0; i < hours; i++)
        DateTime.utc(
          2026,
          10,
          15,
        ).add(Duration(hours: i)).toIso8601String().substring(0, 16),
    ],
    'temperature_2m': <Object?>[
      for (var i = 0; i < hours; i++) 10.0 + i % 24 / 4,
    ],
    'apparent_temperature': <Object?>[
      for (var i = 0; i < hours; i++) 8.0 + i % 24 / 4,
    ],
    'precipitation_probability': <Object?>[
      for (var i = 0; i < hours; i++) i % 3 * 30,
    ],
    'precipitation': <Object?>[
      for (var i = 0; i < hours; i++) i == 30 ? 1.4 : 0.0,
    ],
    'snowfall': <Object?>[for (var i = 0; i < hours; i++) 0.0],
    'weather_code': <Object?>[for (var i = 0; i < hours; i++) i == 30 ? 63 : 2],
    'wind_gusts_10m': <Object?>[for (var i = 0; i < hours; i++) 20.0],
  },
};

void main() {
  group('WeatherRemoteDataSourceImpl', () {
    late Dio dio;
    late DioAdapter adapter;
    late WeatherRemoteDataSourceImpl source;

    setUp(() {
      dio = Dio(BaseOptions(baseUrl: WeatherRemoteDataSourceImpl.baseUrl));
      adapter = DioAdapter(dio: dio);
      source = WeatherRemoteDataSourceImpl(dio);
    });

    test(
      'asks Open-Meteo for three days of hourly fields in local time',
      () async {
        adapter.onGet(
          '/forecast',
          (server) => server.reply(200, openMeteoJson()),
          queryParameters: {
            'latitude': 40.71,
            'longitude': -74.01,
            'timezone': 'auto',
            'forecast_days': 3,
            'hourly':
                'temperature_2m,apparent_temperature,precipitation_probability,'
                'precipitation,snowfall,weather_code,wind_gusts_10m',
          },
        );
        final json = await source.fetchForecast(
          latitude: 40.71,
          longitude: -74.01,
        );
        expect(json['utc_offset_seconds'], -14400);
      },
    );

    test('reports an unreachable server as a network problem', () async {
      adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
      for (final type in [
        DioExceptionType.connectionError,
        DioExceptionType.connectionTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        adapter.onGet(
          '/forecast',
          (server) => server.throws(
            0,
            DioException(requestOptions: RequestOptions(), type: type),
          ),
        );
        await expectLater(
          source.fetchForecast(latitude: 1, longitude: 2),
          throwsA(isA<NetworkException>()),
          reason: '$type',
        );
      }
    });

    test(
      'reports an error status or an unreadable body as a server problem',
      () async {
        adapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
        adapter.onGet(
          '/forecast',
          (server) => server.reply(500, {'error': true}),
          queryParameters: null,
        );
        await expectLater(
          source.fetchForecast(latitude: 1, longitude: 2),
          throwsA(isA<ServerException>()),
        );
        adapter.onGet(
          '/forecast',
          (server) => server.reply(200, ['not', 'an', 'object']),
          queryParameters: null,
        );
        await expectLater(
          source.fetchForecast(latitude: 1, longitude: 2),
          throwsA(isA<ServerException>()),
        );
      },
    );
  });

  group('OpenMeteoForecastModel', () {
    final fetchedAt = DateTime.utc(2026, 10, 15, 18);

    test('reads every hour in the place’s wall-clock time', () {
      final forecast = OpenMeteoForecastModel.fromJson(
        openMeteoJson(),
        fetchedAt: fetchedAt,
      );
      expect(forecast.hours, hasLength(48));
      expect(forecast.utcOffset, const Duration(hours: -4));
      expect(forecast.fetchedAt, fetchedAt);
      final rainy = forecast.hours[30];
      expect(rainy.time, DateTime.utc(2026, 10, 16, 6));
      expect(rainy.time.isUtc, isTrue);
      expect(rainy.temperature, 11.5);
      expect(rainy.feelsLike, 9.5);
      expect(rainy.precipitationProbability, 0);
      expect(rainy.precipitation, 1.4);
      expect(rainy.weatherCode, 63);
      expect(rainy.windGusts, 20);
      expect(forecast.hours[31].precipitationProbability, 30);
    });

    test('treats missing amounts as none and skips hours without readings', () {
      final json = openMeteoJson(hours: 3);
      final hourly = json['hourly']! as Map<String, Object?>;
      (hourly['precipitation']! as List<Object?>)[0] = null;
      (hourly['precipitation_probability']! as List<Object?>)[0] = null;
      (hourly['temperature_2m']! as List<Object?>)[1] = null;
      final forecast = OpenMeteoForecastModel.fromJson(
        json,
        fetchedAt: fetchedAt,
      );
      expect(forecast.hours.map((hour) => hour.time.hour), [0, 2]);
      expect(forecast.hours.first.precipitation, 0);
      expect(forecast.hours.first.precipitationProbability, 0);
    });

    test('rejects an answer without matching hourly lists', () {
      final json = openMeteoJson(hours: 3);
      (json['hourly']! as Map<String, Object?>)['weather_code'] = [1];
      expect(
        () => OpenMeteoForecastModel.fromJson(json, fetchedAt: fetchedAt),
        throwsFormatException,
      );
      expect(
        () => OpenMeteoForecastModel.fromJson({
          'utc_offset_seconds': 0,
        }, fetchedAt: fetchedAt),
        throwsFormatException,
      );
    });
  });
}
