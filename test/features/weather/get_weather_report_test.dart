import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:mockito/mockito.dart';

import 'forecast_fixtures.dart';
import 'weather_repository_test.mocks.dart';

const _place = UserLocation(latitude: 40.71, longitude: -74.01);

void main() {
  late MockWeatherRepository repository;

  setUp(() {
    repository = MockWeatherRepository();
    when(
      repository.forecastFor(any),
    ).thenAnswer((_) async => Right(forecastWith({})));
  });

  /// The report at [localTime] in the forecast's place, four hours behind UTC.
  Future<WeatherReport> reportAt(
    DateTime localTime, {
    ForecastDay? day,
    Occasion? occasion,
    Map<DateTime, Occasion> chosen = const {},
  }) async {
    final result = await withClock(
      Clock.fixed(localTime.add(const Duration(hours: 4))),
      () => GetWeatherReport(repository)(
        WeatherReportParams(
          location: _place,
          day: day,
          occasion: occasion,
          chosen: chosen,
        ),
      ),
    );
    return result.getOrElse(() => throw StateError('$result'));
  }

  test('reports tomorrow by default, for its default occasion', () async {
    final report = await reportAt(DateTime.utc(2026, 10, 15, 15, 30));
    expect(report.day, ForecastDay.tomorrow);
    expect(report.weather.date, DateTime.utc(2026, 10, 16));
    expect(report.weather.occasion, Occasion.work);
    expect(report.isSaved, isFalse);
    verify(repository.forecastFor(_place)).called(1);
  });

  test('reports today from six to nine in the morning', () async {
    final report = await reportAt(DateTime.utc(2026, 10, 16, 7, 30));
    expect(report.day, ForecastDay.today);
    expect(report.weather.date, DateTime.utc(2026, 10, 16));
  });

  test('reports the day and occasion asked for', () async {
    final report = await reportAt(
      DateTime.utc(2026, 10, 15, 18),
      day: ForecastDay.today,
      occasion: Occasion.goingOut,
    );
    expect(report.day, ForecastDay.today);
    expect(report.weather.date, DateTime.utc(2026, 10, 15));
    expect(report.weather.occasion, Occasion.goingOut);
  });

  test("uses the occasion chosen for the day's own date, never another "
      "day's", () async {
    final chosen = {DateTime.utc(2026, 10, 15): Occasion.goingOut};
    final morning = await reportAt(
      DateTime.utc(2026, 10, 16, 7, 30),
      chosen: chosen,
    );
    expect(morning.weather.date, DateTime.utc(2026, 10, 16));
    expect(morning.weather.occasion, Occasion.work);
    final evening = await reportAt(
      DateTime.utc(2026, 10, 14, 18),
      chosen: chosen,
    );
    expect(evening.weather.date, DateTime.utc(2026, 10, 15));
    expect(evening.weather.occasion, Occasion.goingOut);
  });

  test('marks a forecast an hour old or more as saved', () async {
    final report = await reportAt(DateTime.utc(2026, 10, 15, 15));
    expect(report.fetchedAt, forecastFetchedAt);
    expect(report.isSaved, isFalse);
    final later = await reportAt(DateTime.utc(2026, 10, 15, 16));
    expect(later.isSaved, isTrue);
  });

  test('fails when the forecast does not reach the day', () async {
    expect(
      await withClock(
        Clock.fixed(DateTime.utc(2026, 10, 20, 12)),
        () => GetWeatherReport(repository)(
          const WeatherReportParams(location: _place),
        ),
      ),
      const Left<Failure, WeatherReport>(ServerFailure()),
    );
  });

  test('passes on a failure to get the forecast', () async {
    when(
      repository.forecastFor(any),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    final useCase = GetWeatherReport(repository);
    expect(
      await useCase(const WeatherReportParams(location: _place)),
      const Left<Failure, WeatherReport>(NetworkFailure()),
    );
  });
}
