import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
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

const _chosen = PhotoState(status: PhotoStatus.chosen, path: '/tmp/new.jpg');

void main() {
  late MockPhotoRepository repository;

  PhotoBloc buildBloc({PhotoRole role = PhotoRole.body}) => PhotoBloc(
    role: role,
    choosePhoto: ChoosePhoto(repository),
    keepPhoto: KeepPhoto(repository),
    getKeptPhoto: GetKeptPhoto(repository),
  );

  setUp(() {
    repository = MockPhotoRepository();
    when(repository.kept(any)).thenAnswer((_) async => const Right(null));
    when(
      repository.choose(any),
    ).thenAnswer((_) async => const Right(ChosenPhoto(path: '/tmp/new.jpg')));
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
      'shows the kept photo',
      build: () {
        when(
          repository.kept(PhotoRole.body),
        ).thenAnswer((_) async => const Right(_kept));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PhotoLoaded()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/app/body-1.jpg',
          isKept: true,
        ),
      ],
    );
  });

  group('choosing', () {
    blocTest<PhotoBloc, PhotoState>(
      'shows the photo the person chose, made ready for its role',
      build: () => buildBloc(role: PhotoRole.face),
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [const PhotoState(busy: true), _chosen],
      verify: (_) => verify(repository.choose(PhotoRole.face)).called(1),
    );

    blocTest<PhotoBloc, PhotoState>(
      'shows a converted photo as converted',
      build: () {
        when(repository.choose(any)).thenAnswer(
          (_) async => const Right(
            ChosenPhoto(path: '/tmp/new-ready.png', converted: true),
          ),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [
        const PhotoState(busy: true),
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/tmp/new-ready.png',
          converted: true,
        ),
      ],
    );

    blocTest<PhotoBloc, PhotoState>(
      'keeps the photo on screen when the next one is too small',
      build: () {
        when(repository.choose(any)).thenAnswer(
          (_) async => const Left(PhotoFailure(PhotoProblem.tooSmall)),
        );
        return buildBloc();
      },
      seed: () => _chosen,
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/tmp/new.jpg',
          busy: true,
        ),
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/tmp/new.jpg',
          failure: PhotoFailure(PhotoProblem.tooSmall),
        ),
      ],
    );

    blocTest<PhotoBloc, PhotoState>(
      'keeps the screen as it was when the person cancels',
      build: () {
        when(repository.choose(any)).thenAnswer((_) async => const Right(null));
        return buildBloc();
      },
      seed: () => _chosen,
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/tmp/new.jpg',
          busy: true,
        ),
        _chosen,
      ],
    );

    blocTest<PhotoBloc, PhotoState>(
      'says when a photo cannot be opened and keeps the screen as it was',
      build: () {
        when(repository.choose(any)).thenAnswer(
          (_) async => const Left(PhotoFailure(PhotoProblem.unreadable)),
        );
        return buildBloc();
      },
      act: (bloc) => bloc.add(const PhotoChooseRequested()),
      expect: () => [
        const PhotoState(busy: true),
        const PhotoState(failure: PhotoFailure(PhotoProblem.unreadable)),
      ],
    );

    test('ignores more taps while it is busy', () async {
      final chosen = Completer<Either<Failure, ChosenPhoto?>>();
      when(repository.choose(any)).thenAnswer((_) => chosen.future);
      final bloc = buildBloc();
      addTearDown(bloc.close);
      bloc
        ..add(const PhotoChooseRequested())
        ..add(const PhotoChooseRequested())
        ..add(const PhotoConfirmed());
      await Future<void>.delayed(Duration.zero);
      chosen.complete(const Right(ChosenPhoto(path: '/tmp/new.jpg')));
      await bloc.stream.firstWhere((state) => !state.busy);
      verify(repository.choose(any)).called(1);
      verifyNever(repository.keep(any, any));
    });
  });

  group('confirming', () {
    blocTest<PhotoBloc, PhotoState>(
      'keeps the chosen photo, then confirms',
      build: buildBloc,
      seed: () => _chosen,
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.chosen,
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
      'keeps a converted photo as converted',
      build: buildBloc,
      seed: () => const PhotoState(
        status: PhotoStatus.chosen,
        path: '/tmp/new-ready.png',
        converted: true,
      ),
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/tmp/new-ready.png',
          converted: true,
          busy: true,
        ),
        const PhotoState(
          status: PhotoStatus.confirmed,
          path: '/app/body-2.jpg',
          isKept: true,
          converted: true,
        ),
      ],
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
          status: PhotoStatus.chosen,
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
      seed: () => _chosen,
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => [
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/tmp/new.jpg',
          busy: true,
        ),
        const PhotoState(
          status: PhotoStatus.chosen,
          path: '/tmp/new.jpg',
          failure: CacheFailure(),
        ),
      ],
    );

    blocTest<PhotoBloc, PhotoState>(
      'ignores Continue without a photo',
      build: buildBloc,
      act: (bloc) => bloc.add(const PhotoConfirmed()),
      expect: () => <PhotoState>[],
    );
  });
}
