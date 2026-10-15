import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/check_full_length.dart';
import 'package:in_vogue/features/photos/domain/usecases/choose_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/keep_photo.dart';
import 'package:in_vogue/features/photos/presentation/bloc/photo_bloc.dart';
import 'package:mockito/mockito.dart';

import 'photo_repository_test.mocks.dart';

const _kept = UserPhoto(
  role: PhotoRole.body,
  path: '/app/body-1.jpg',
  revision: 1,
);

const _passed = PhotoState(status: PhotoStatus.passed, path: '/tmp/new.jpg');

void main() {
  late MockPhotoRepository repository;

  PhotoBloc buildBloc({PhotoRole role = PhotoRole.body}) => PhotoBloc(
    role: role,
    choosePhoto: ChoosePhoto(repository),
    checkFullLength: CheckFullLength(repository),
    keepPhoto: KeepPhoto(repository),
    getKeptPhoto: GetKeptPhoto(repository),
  );

  setUp(() {
    repository = MockPhotoRepository();
    when(repository.kept(any)).thenAnswer((_) async => const Right(null));
    when(
      repository.choose(),
    ).thenAnswer((_) async => const Right('/tmp/new.jpg'));
    when(
      repository.isFullLength(any),
    ).thenAnswer((_) async => const Right(true));
    when(repository.keep(any, any)).thenAnswer(
      (_) async => const Right(
        UserPhoto(role: PhotoRole.body, path: '/app/body-2.jpg', revision: 2),
      ),
    );
  });

  group('on start', () {
    blocTest<PhotoBloc, PhotoState>(
      'shows the example when no photo is kept',
      build: buildBloc,
      act: (bloc) => bloc.add(const PhotoLoaded()),
      expect: () => <PhotoState>[],
    );

    blocTest<PhotoBloc, PhotoState>(
      'shows the kept photo, which has already passed',
      build: () {
        when(
          repository.kept(PhotoRole.body),
        ).thenAnswer((_) async => const Right(_kept));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PhotoLoaded()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.passed,
          path: '/app/body-1.jpg',
          isKept: true,
        ),
      ],
    );
  });

  group('choosing', () {
    blocTest<PhotoBloc, PhotoState>(
      'checks a chosen photo and passes it when it is full length',
      build: buildBloc,
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [const PhotoState(busy: true), _passed],
      verify: (_) => verify(repository.isFullLength('/tmp/new.jpg')).called(1),
    );

    blocTest<PhotoBloc, PhotoState>(
      'rejects a photo that is not full length',
      build: () {
        when(
          repository.isFullLength(any),
        ).thenAnswer((_) async => const Right(false));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [
        const PhotoState(busy: true),
        const PhotoState(status: PhotoStatus.rejected, path: '/tmp/new.jpg'),
      ],
    );

    blocTest<PhotoBloc, PhotoState>(
      'keeps the screen as it was when the person cancels',
      build: () {
        when(repository.choose()).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => _passed,
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.passed,
          path: '/tmp/new.jpg',
          busy: true,
        ),
        _passed,
      ],
      verify: (_) => verifyNever(repository.isFullLength(any)),
    );

    blocTest<PhotoBloc, PhotoState>(
      'says when a photo cannot be read and keeps the screen as it was',
      build: () {
        when(
          repository.isFullLength(any),
        ).thenAnswer((_) async => const Left(PhotoFailure()));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [
        const PhotoState(busy: true),
        const PhotoState(failure: PhotoFailure()),
      ],
    );

    blocTest<PhotoBloc, PhotoState>(
      'does not check a face photo for full length',
      build: () => buildBloc(role: PhotoRole.face),
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [const PhotoState(busy: true), _passed],
      verify: (_) => verifyNever(repository.isFullLength(any)),
    );

    test('ignores more taps while it is busy', () async {
      final chosen = Completer<Either<Failure, String?>>();
      when(repository.choose()).thenAnswer((_) => chosen.future);
      final bloc = buildBloc();
      addTearDown(bloc.close);
      bloc
        ..add(const PhotoChooseRequested())
        ..add(const PhotoChooseRequested())
        ..add(const PhotoConfirmed());
      await Future<void>.delayed(Duration.zero);
      chosen.complete(const Right('/tmp/new.jpg'));
      await bloc.stream.firstWhere((state) => !state.busy);
      verify(repository.choose()).called(1);
      verifyNever(repository.keep(any, any));
    });
  });

  group('confirming', () {
    blocTest<PhotoBloc, PhotoState>(
      'keeps the chosen photo, then confirms',
      build: buildBloc,
      seed: () => _passed,
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.passed,
          path: '/tmp/new.jpg',
          busy: true,
        ),
        const PhotoState(
          status: PhotoStatus.confirmed,
          path: '/app/body-2.jpg',
          isKept: true,
        ),
      ],
      verify: (_) =>
          verify(repository.keep('/tmp/new.jpg', PhotoRole.body)).called(1),
    );

    blocTest<PhotoBloc, PhotoState>(
      'confirms the kept photo again without keeping it twice',
      build: buildBloc,
      seed: () => const PhotoState(
        status: PhotoStatus.confirmed,
        path: '/app/body-1.jpg',
        isKept: true,
      ),
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.passed,
          path: '/app/body-1.jpg',
          isKept: true,
          busy: true,
        ),
        const PhotoState(
          status: PhotoStatus.confirmed,
          path: '/app/body-1.jpg',
          isKept: true,
        ),
      ],
      verify: (_) => verifyNever(repository.keep(any, any)),
    );

    blocTest<PhotoBloc, PhotoState>(
      'says when the photo cannot be kept',
      build: () {
        when(
          repository.keep(any, any),
        ).thenAnswer((_) async => const Left(CacheFailure()));
        return buildBloc();
      },
      seed: () => _passed,
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.passed,
          path: '/tmp/new.jpg',
          busy: true,
        ),
        const PhotoState(
          status: PhotoStatus.passed,
          path: '/tmp/new.jpg',
          failure: CacheFailure(),
        ),
      ],
    );

    blocTest<PhotoBloc, PhotoState>(
      'ignores Continue without a photo that passed',
      build: buildBloc,
      seed: () =>
          const PhotoState(status: PhotoStatus.rejected, path: '/tmp/new.jpg'),
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => <PhotoState>[],
    );
  });
}
