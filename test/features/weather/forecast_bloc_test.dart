import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:in_vogue/features/weather/presentation/bloc/forecast_bloc.dart';
import 'package:mockito/mockito.dart';

import '../location/location_repository_test.mocks.dart';
import 'forecast_fixtures.dart';
import 'weather_repository_test.mocks.dart';

const _place = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);

/// 15 October 2026, 15:30 in New York.
final _now = DateTime.utc(2026, 10, 15, 19, 30);

void main() {
  late MockLocationRepository locations;
  late MockWeatherRepository weather;

  setUp(() {
    locations = MockLocationRepository();
    weather = MockWeatherRepository();
    when(
      locations.savedLocation(),
    ).thenAnswer((_) async => const Right(_place));
    when(
      weather.forecastFor(any),
    ).thenAnswer((_) async => Right(forecastWith({})));
  });

  ForecastBloc buildBloc() => withClock(
    Clock.fixed(_now),
    () => ForecastBloc(
      getSavedLocation: GetSavedLocation(locations),
      getWeatherReport: GetWeatherReport(weather),
    ),
  );

  test('starts loading', () {
    expect(buildBloc().state, const ForecastState());
  });

  blocTest<ForecastBloc, ForecastState>(
    'shows tomorrow’s weather for the saved place',
    build: buildBloc,
    act: (bloc) => bloc.add(const ForecastRequested()),
    expect: () => [
      isA<ForecastState>()
          .having((s) => s.status, 'status', ForecastStatus.ready)
          .having((s) => s.place, 'place', _place)
          .having((s) => s.report?.day, 'day', ForecastDay.tomorrow)
          .having(
            (s) => s.report?.weather.date,
            'date',
            DateTime.utc(2026, 10, 16),
          ),
    ],
    verify: (_) => verify(weather.forecastFor(_place)).called(1),
  );

  blocTest<ForecastBloc, ForecastState>(
    'says when the weather cannot be had, and loads again on request',
    build: () {
      when(
        weather.forecastFor(any),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const ForecastRequested());
      await bloc.stream.firstWhere((s) => s.status == ForecastStatus.failed);
      when(
        weather.forecastFor(any),
      ).thenAnswer((_) async => Right(forecastWith({})));
      bloc.add(const ForecastRequested());
    },
    expect: () => [
      const ForecastState(status: ForecastStatus.failed, place: _place),
      const ForecastState(place: _place),
      isA<ForecastState>().having(
        (s) => s.status,
        'status',
        ForecastStatus.ready,
      ),
    ],
  );

  blocTest<ForecastBloc, ForecastState>(
    'cannot show the weather without a saved place',
    build: () {
      when(
        locations.savedLocation(),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const ForecastRequested()),
    expect: () => [const ForecastState(status: ForecastStatus.failed)],
    verify: (_) => verifyNever(weather.forecastFor(any)),
  );
}
