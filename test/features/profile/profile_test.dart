import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:in_vogue/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:in_vogue/features/profile/domain/repositories/profile_repository.dart';
import 'package:in_vogue/features/profile/domain/usecases/get_profile_name.dart';
import 'package:in_vogue/features/profile/domain/usecases/save_profile_name.dart';
import 'package:in_vogue/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/memory_store.dart';
import '../auth/sign_in_bloc_test.mocks.dart';
import 'profile_test.mocks.dart';

@GenerateMocks([ProfileRepository, KeyValueStore])
void main() {
  group('ProfileRepositoryImpl', () {
    test('keeps the name on the phone, trimmed', () async {
      final store = MemoryStore();
      final repository = ProfileRepositoryImpl(
        ProfileLocalDataSourceImpl(store),
      );
      expect(await repository.name(), const Right<Failure, String?>(null));
      expect(
        await repository.saveName('  Maya '),
        const Right<Failure, String>('Maya'),
      );
      expect(await repository.name(), const Right<Failure, String?>('Maya'));
    });

    test('reports a store that cannot be read or written', () async {
      final store = MockKeyValueStore();
      when(
        store.readString(any),
      ).thenThrow(CacheException(Exception('closed'), StackTrace.current));
      when(
        store.writeString(any, any),
      ).thenThrow(CacheException(Exception('full'), StackTrace.current));
      final repository = ProfileRepositoryImpl(
        ProfileLocalDataSourceImpl(store),
      );
      expect(
        await repository.name(),
        const Left<Failure, String?>(CacheFailure()),
      );
      expect(
        await repository.saveName('Maya'),
        const Left<Failure, String>(CacheFailure()),
      );
    });
  });

  group('ProfileBloc', () {
    late MockProfileRepository profile;
    late MockAuthRepository auth;
    late MockAccountSync sync;

    ProfileBloc buildBloc() => ProfileBloc(
      getProfileName: GetProfileName(profile),
      saveProfileName: SaveProfileName(profile),
      getCurrentAccount: GetCurrentAccount(auth),
      accountSync: sync,
    );

    setUp(() {
      profile = MockProfileRepository();
      auth = MockAuthRepository();
      sync = MockAccountSync();
      when(sync.nameRestored).thenAnswer((_) async {});
      when(sync.save(any)).thenAnswer((_) async => const Right(unit));
      when(profile.name()).thenAnswer((_) async => const Right(null));
      when(
        auth.currentAccount(),
      ).thenAnswer((_) async => const Right(Account(id: 'u', name: 'Maya')));
      when(profile.saveName(any)).thenAnswer(
        (invocation) async =>
            Right((invocation.positionalArguments.first as String).trim()),
      );
    });

    blocTest<ProfileBloc, ProfileState>(
      'fills in the name the provider shared',
      build: buildBloc,
      act: (bloc) => bloc.add(const ProfileLoaded()),
      expect: () => [
        const ProfileState(status: ProfileStatus.ready, name: 'Maya'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'prefers the name the person saved',
      build: () {
        when(profile.name()).thenAnswer((_) async => const Right('May'));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoaded()),
      expect: () => [
        const ProfileState(status: ProfileStatus.ready, name: 'May'),
      ],
    );

    test("waits for the account's name before the provider's", () async {
      final restored = Completer<void>();
      when(sync.nameRestored).thenAnswer((_) => restored.future);
      final bloc = buildBloc();
      addTearDown(bloc.close);
      bloc.add(const ProfileLoaded());
      await pumpEventQueue();
      expect(bloc.state.status, ProfileStatus.loading);
      when(profile.name()).thenAnswer((_) async => const Right('May'));
      restored.complete();
      expect(
        await bloc.stream.first,
        const ProfileState(status: ProfileStatus.ready, name: 'May'),
      );
    });

    test('keeps a name saved while it waited', () async {
      final restored = Completer<void>();
      when(sync.nameRestored).thenAnswer((_) => restored.future);
      final bloc = buildBloc();
      addTearDown(bloc.close);
      bloc
        ..add(const ProfileLoaded())
        ..add(const ProfileNameSaved('Maya K'));
      await bloc.stream.firstWhere((s) => s.status == ProfileStatus.saved);
      restored.complete();
      await pumpEventQueue();
      expect(
        bloc.state,
        const ProfileState(status: ProfileStatus.saved, name: 'Maya K'),
      );
    });

    blocTest<ProfileBloc, ProfileState>(
      'starts empty when nobody shared a name',
      build: () {
        when(auth.currentAccount()).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const ProfileLoaded()),
      expect: () => [const ProfileState(status: ProfileStatus.ready)],
    );

    blocTest<ProfileBloc, ProfileState>(
      'saves the name',
      build: buildBloc,
      seed: () => const ProfileState(status: ProfileStatus.ready),
      act: (bloc) => bloc.add(const ProfileNameSaved(' Maya ')),
      expect: () => [
        const ProfileState(status: ProfileStatus.saving, name: ' Maya '),
        const ProfileState(status: ProfileStatus.saved, name: 'Maya'),
      ],
      verify: (_) => verify(sync.save('u')).called(1),
    );

    blocTest<ProfileBloc, ProfileState>(
      'moves on without waiting for the account',
      build: () {
        when(
          sync.save(any),
        ).thenAnswer((_) => Completer<Either<Failure, Unit>>().future);
        return buildBloc();
      },
      seed: () => const ProfileState(status: ProfileStatus.ready),
      act: (bloc) => bloc.add(const ProfileNameSaved('Maya')),
      expect: () => [
        const ProfileState(status: ProfileStatus.saving, name: 'Maya'),
        const ProfileState(status: ProfileStatus.saved, name: 'Maya'),
      ],
    );

    blocTest<ProfileBloc, ProfileState>(
      'says when the name cannot be saved',
      build: () {
        when(
          profile.saveName(any),
        ).thenAnswer((_) async => const Left(CacheFailure()));
        return buildBloc();
      },
      seed: () => const ProfileState(status: ProfileStatus.ready),
      act: (bloc) => bloc.add(const ProfileNameSaved('Maya')),
      expect: () => [
        const ProfileState(status: ProfileStatus.saving, name: 'Maya'),
        const ProfileState(
          status: ProfileStatus.ready,
          name: 'Maya',
          failure: CacheFailure(),
        ),
      ],
      verify: (_) => verifyNever(sync.save(any)),
    );

    blocTest<ProfileBloc, ProfileState>(
      'does not save an empty name',
      build: buildBloc,
      seed: () => const ProfileState(status: ProfileStatus.ready),
      act: (bloc) => bloc.add(const ProfileNameSaved('   ')),
      expect: () => <ProfileState>[],
      verify: (_) => verifyNever(profile.saveName(any)),
    );
  });
}
