import 'package:bloc_test/bloc_test.dart';
import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/get_saved_location.dart';
import 'package:in_vogue/features/outfits/domain/entities/tried_on_outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/usecases/try_on_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/setup/presentation/bloc/first_outfit_bloc.dart';
import 'package:in_vogue/features/weather/domain/usecases/get_weather_report.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../location/location_repository_test.mocks.dart';
import '../photos/photo_repository_test.mocks.dart';
import '../weather/forecast_fixtures.dart';
import '../weather/weather_repository_test.mocks.dart';
import 'first_outfit_bloc_test.mocks.dart';

const _place = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);
const _photo = UserPhoto(
  role: PhotoRole.body,
  path: '/app/body-1.jpg',
  revision: 1,
);
const _outfit = TriedOnOutfit(
  imagePath: '/app/outfit-1.jpg',
  description: 'You in a camel mac and navy trousers',
  reason: 'A mac for the showers after 2 pm.',
);

/// 15 October 2026, 15:30 in New York.
final _now = DateTime.utc(2026, 10, 15, 19, 30);

@GenerateMocks([TryOnRepository])
void main() {
  late MockLocationRepository locations;
  late MockPhotoRepository photos;
  late MockWeatherRepository weather;
  late MockTryOnRepository tryOn;

  setUp(() {
    locations = MockLocationRepository();
    photos = MockPhotoRepository();
    weather = MockWeatherRepository();
    tryOn = MockTryOnRepository();
    when(
      locations.savedLocation(),
    ).thenAnswer((_) async => const Right(_place));
    when(
      photos.kept(PhotoRole.body),
    ).thenAnswer((_) async => const Right(_photo));
    when(
      weather.forecastFor(any),
    ).thenAnswer((_) async => Right(forecastWith({})));
    when(
      tryOn.tryOn(photo: anyNamed('photo'), weather: anyNamed('weather')),
    ).thenAnswer((_) async => const Right(_outfit));
  });

  FirstOutfitBloc buildBloc() => withClock(
    Clock.fixed(_now),
    () => FirstOutfitBloc(
      getSavedLocation: GetSavedLocation(locations),
      getKeptPhoto: GetKeptPhoto(photos),
      getWeatherReport: GetWeatherReport(weather),
      tryOnOutfit: TryOnOutfit(tryOn),
    ),
  );

  test('starts with everything still to come', () {
    expect(buildBloc().state, const FirstOutfitState());
  });

  blocTest<FirstOutfitBloc, FirstOutfitState>(
    'shows tomorrow’s weather, then the outfit once it is on',
    build: buildBloc,
    act: (bloc) => bloc.add(const FirstOutfitStarted()),
    wait: Duration.zero,
    verify: (bloc) {
      final state = bloc.state;
      expect(state.location, _place);
      expect(state.photo, _photo);
      expect(state.weather, Progress.ready);
      expect(state.report?.day, ForecastDay.tomorrow);
      expect(state.report?.weather.date, DateTime.utc(2026, 10, 16));
      expect(state.outfit, Progress.ready);
      expect(state.triedOn, _outfit);
      final dressed = verify(
        tryOn.tryOn(
          photo: captureAnyNamed('photo'),
          weather: captureAnyNamed('weather'),
        ),
      ).captured;
      expect(dressed.first, _photo);
      expect(dressed.last, state.report?.weather);
    },
  );

  blocTest<FirstOutfitBloc, FirstOutfitState>(
    'shows the weather before the try-on finishes',
    build: buildBloc,
    act: (bloc) => bloc.add(const FirstOutfitStarted()),
    expect: () => [
      isA<FirstOutfitState>()
          .having((s) => s.weather, 'weather', Progress.loading)
          .having((s) => s.photo, 'photo', _photo),
      isA<FirstOutfitState>()
          .having((s) => s.weather, 'weather', Progress.ready)
          .having((s) => s.outfit, 'outfit', Progress.loading),
      isA<FirstOutfitState>().having((s) => s.outfit, 'outfit', Progress.ready),
    ],
  );

  blocTest<FirstOutfitBloc, FirstOutfitState>(
    'says when the weather cannot be had, and does not try anything on',
    build: () {
      when(
        weather.forecastFor(any),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const FirstOutfitStarted()),
    verify: (bloc) {
      expect(bloc.state.weather, Progress.failed);
      verifyNever(
        tryOn.tryOn(photo: anyNamed('photo'), weather: anyNamed('weather')),
      );
    },
  );

  blocTest<FirstOutfitBloc, FirstOutfitState>(
    'tries the weather again, then the outfit',
    build: () {
      when(
        weather.forecastFor(any),
      ).thenAnswer((_) async => const Left(NetworkFailure()));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const FirstOutfitStarted());
      await bloc.stream.firstWhere((s) => s.weather == Progress.failed);
      when(
        weather.forecastFor(any),
      ).thenAnswer((_) async => Right(forecastWith({})));
      bloc.add(const FirstOutfitWeatherRetried());
    },
    verify: (bloc) {
      expect(bloc.state.weather, Progress.ready);
      expect(bloc.state.outfit, Progress.ready);
    },
  );

  blocTest<FirstOutfitBloc, FirstOutfitState>(
    'keeps the weather when the try-on fails, and tries it again',
    build: () {
      when(
        tryOn.tryOn(photo: anyNamed('photo'), weather: anyNamed('weather')),
      ).thenAnswer((_) async => const Left(ServerFailure()));
      return buildBloc();
    },
    act: (bloc) async {
      bloc.add(const FirstOutfitStarted());
      await bloc.stream.firstWhere((s) => s.outfit == Progress.failed);
      expect(bloc.state.weather, Progress.ready);
      when(
        tryOn.tryOn(photo: anyNamed('photo'), weather: anyNamed('weather')),
      ).thenAnswer((_) async => const Right(_outfit));
      bloc.add(const FirstOutfitTryOnRetried());
    },
    verify: (bloc) {
      expect(bloc.state.outfit, Progress.ready);
      verify(weather.forecastFor(any)).called(1);
    },
  );

  blocTest<FirstOutfitBloc, FirstOutfitState>(
    'cannot dress a person without their photo',
    build: () {
      when(
        photos.kept(PhotoRole.body),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const FirstOutfitStarted()),
    verify: (bloc) {
      expect(bloc.state.weather, Progress.ready);
      expect(bloc.state.outfit, Progress.failed);
      verifyNever(
        tryOn.tryOn(photo: anyNamed('photo'), weather: anyNamed('weather')),
      );
    },
  );

  blocTest<FirstOutfitBloc, FirstOutfitState>(
    'cannot get the weather without a saved location',
    build: () {
      when(
        locations.savedLocation(),
      ).thenAnswer((_) async => const Right(null));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const FirstOutfitStarted()),
    verify: (bloc) {
      expect(bloc.state.weather, Progress.failed);
      verifyNever(weather.forecastFor(any));
    },
  );
}
