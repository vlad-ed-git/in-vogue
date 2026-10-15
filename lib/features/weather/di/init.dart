import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_local_data_source.dart';
import 'package:in_vogue/features/weather/data/data_sources/weather_remote_data_source.dart';
import 'package:in_vogue/features/weather/data/repositories/weather_repository_impl.dart';
import 'package:in_vogue/features/weather/domain/repositories/weather_repository.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';

void init(GetIt locator) {
  locator
    ..registerLazySingleton<WeatherRemoteDataSource>(
      () => WeatherRemoteDataSourceImpl(
        Dio(
          BaseOptions(
            baseUrl: WeatherRemoteDataSourceImpl.baseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
          ),
        ),
      ),
    )
    ..registerLazySingleton<WeatherLocalDataSource>(
      () => WeatherLocalDataSourceImpl(locator()),
    )
    ..registerLazySingleton<WeatherRepository>(
      () => WeatherRepositoryImpl(
        remoteDataSource: locator(),
        localDataSource: locator(),
        logMessages: locator(),
      ),
    )
    ..registerLazySingleton<GetWeatherReport>(
      () => GetWeatherReport(locator()),
    );
}
