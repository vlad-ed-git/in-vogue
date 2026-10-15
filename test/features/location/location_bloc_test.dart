import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/location/domain/entities/user_location.dart';
import 'package:in_vogue/features/location/domain/usecases/locate_user.dart';
import 'package:in_vogue/features/location/domain/usecases/open_location_settings.dart';
import 'package:in_vogue/features/location/presentation/bloc/location_bloc.dart';
import 'package:mockito/mockito.dart';

import 'location_repository_test.mocks.dart';

const _newYork = UserLocation(
  latitude: 40.71,
  longitude: -74.01,
  city: 'New York',
  countryCode: 'US',
);

const _refused = LocationState(
  status: LocationStatus.failed,
  failure: LocationFailure(LocationProblem.deniedForever),
);

void main() {
  late MockLocationRepository repository;
  LocationBloc buildBloc() => LocationBloc(
    locateUser: LocateUser(repository),
    openLocationSettings: OpenLocationSettings(repository),
  );

  setUp(() {
    repository = MockLocationRepository();
    when(
      repository.locate(
        askPermission: anyNamed('askPermission'),
        languageCode: anyNamed('languageCode'),
      ),
    ).thenAnswer((_) async => const Right(_newYork));
    when(repository.openSettings(any)).thenAnswer((_) async {});
  });

  blocTest<LocationBloc, LocationState>(
    'asks for and announces the location',
    build: buildBloc,
    act: (bloc) => bloc.add(const LocationRequested('es')),
    expect: () => [
      const LocationState(status: LocationStatus.locating),
      const LocationState(status: LocationStatus.located, location: _newYork),
    ],
    verify: (_) => verify(
      repository.locate(askPermission: true, languageCode: 'es'),
    ).called(1),
  );

  blocTest<LocationBloc, LocationState>(
    'shows why the location could not be found',
    build: () {
      when(
        repository.locate(
          askPermission: anyNamed('askPermission'),
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer(
        (_) async => const Left(LocationFailure(LocationProblem.deniedForever)),
      );
      return buildBloc();
    },
    act: (bloc) => bloc.add(const LocationRequested('en')),
    expect: () => [
      const LocationState(status: LocationStatus.locating),
      _refused,
    ],
  );

  test('ignores further taps while it is locating', () async {
    final answer = Completer<Either<Failure, UserLocation>>();
    when(
      repository.locate(
        askPermission: anyNamed('askPermission'),
        languageCode: anyNamed('languageCode'),
      ),
    ).thenAnswer((_) => answer.future);
    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc
      ..add(const LocationRequested('en'))
      ..add(const LocationRequested('en'));
    await Future<void>.delayed(Duration.zero);
    answer.complete(const Right(_newYork));
    await bloc.stream.firstWhere((s) => s.status == LocationStatus.located);
    verify(
      repository.locate(askPermission: true, languageCode: 'en'),
    ).called(1);
  });

  blocTest<LocationBloc, LocationState>(
    'checks again without asking when settings could have helped',
    build: buildBloc,
    seed: () => _refused,
    act: (bloc) => bloc.add(const LocationRechecked('en')),
    expect: () => [
      const LocationState(status: LocationStatus.located, location: _newYork),
    ],
    verify: (_) => verify(
      repository.locate(askPermission: false, languageCode: 'en'),
    ).called(1),
  );

  blocTest<LocationBloc, LocationState>(
    'keeps the notice when the check fails again',
    build: () {
      when(
        repository.locate(
          askPermission: anyNamed('askPermission'),
          languageCode: anyNamed('languageCode'),
        ),
      ).thenAnswer(
        (_) async => const Left(LocationFailure(LocationProblem.deniedForever)),
      );
      return buildBloc();
    },
    seed: () => _refused,
    act: (bloc) => bloc.add(const LocationRechecked('en')),
    expect: () => <LocationState>[],
  );

  blocTest<LocationBloc, LocationState>(
    'does not check again before settings could have helped',
    build: buildBloc,
    seed: () => const LocationState(
      status: LocationStatus.failed,
      failure: LocationFailure(LocationProblem.unavailable),
    ),
    act: (bloc) => bloc
      ..add(const LocationRechecked('en'))
      ..add(const LocationRechecked('en')),
    expect: () => <LocationState>[],
    verify: (_) => verifyNever(
      repository.locate(
        askPermission: anyNamed('askPermission'),
        languageCode: anyNamed('languageCode'),
      ),
    ),
  );

  blocTest<LocationBloc, LocationState>(
    'does not check again on a fresh start',
    build: buildBloc,
    act: (bloc) => bloc.add(const LocationRechecked('en')),
    expect: () => <LocationState>[],
  );

  blocTest<LocationBloc, LocationState>(
    'opens the settings that solve the current problem',
    build: buildBloc,
    seed: () => const LocationState(
      status: LocationStatus.failed,
      failure: LocationFailure(LocationProblem.servicesOff),
    ),
    act: (bloc) => bloc.add(const LocationSettingsRequested()),
    expect: () => <LocationState>[],
    verify: (_) =>
        verify(repository.openSettings(LocationProblem.servicesOff)).called(1),
  );
}
