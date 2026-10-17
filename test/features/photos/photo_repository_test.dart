import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_picker_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_prepare_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_store_data_source.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:in_vogue/features/photos/data/repositories/photo_repository_impl.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'photo_repository_test.mocks.dart';

const _body = UserPhoto(
  role: PhotoRole.body,
  path: '/app/body-1.jpg',
  revision: 1,
);

@GenerateMocks([
  PhotoPickerDataSource,
  PhotoPrepareDataSource,
  PhotoStoreDataSource,
  PhotoRepository,
  LogMessages,
])
void main() {
  late MockPhotoPickerDataSource picker;
  late MockPhotoPrepareDataSource prepare;
  late MockPhotoStoreDataSource store;
  late MockLogMessages logger;
  late PhotoRepositoryImpl repository;

  setUp(() {
    picker = MockPhotoPickerDataSource();
    prepare = MockPhotoPrepareDataSource();
    store = MockPhotoStoreDataSource();
    logger = MockLogMessages();
    repository = PhotoRepositoryImpl(
      pickerDataSource: picker,
      prepareDataSource: prepare,
      storeDataSource: store,
      logMessages: logger,
    );
  });

  PhotoException unreadable() =>
      PhotoException(PlatformException(code: 'unreadable'), StackTrace.current);

  test('makes the chosen photo ready for its role, or none when the person '
      'cancels', () async {
    const ready = ChosenPhoto(path: '/tmp/picked-ready.png', converted: true);
    when(picker.choose()).thenAnswer((_) async => '/tmp/picked.webp');
    when(
      prepare.prepare('/tmp/picked.webp', PhotoRole.face),
    ).thenAnswer((_) async => ready);
    expect(
      await repository.choose(PhotoRole.face),
      const Right<Failure, ChosenPhoto?>(ready),
    );
    when(picker.choose()).thenAnswer((_) async => null);
    expect(
      await repository.choose(PhotoRole.face),
      const Right<Failure, ChosenPhoto?>(null),
    );
    verify(prepare.prepare(any, any)).called(1);
  });

  test('maps a picker problem to a photo failure and logs it', () async {
    final error = unreadable();
    when(picker.choose()).thenThrow(error);
    expect(
      await repository.choose(PhotoRole.body),
      const Left<Failure, ChosenPhoto?>(PhotoFailure(PhotoProblem.unreadable)),
    );
    verify(
      logger.logError(
        callerClass: 'PhotoRepositoryImpl',
        callerMethod: 'choose',
        error: error.cause,
        stackTrace: error.stackTrace,
      ),
    ).called(1);
  });

  test('says why a chosen photo cannot be used', () async {
    when(picker.choose()).thenAnswer((_) async => '/tmp/picked.jpg');
    for (final problem in [PhotoProblem.tooSmall, PhotoProblem.unusable]) {
      when(prepare.prepare(any, any)).thenThrow(
        PhotoException(StateError('$problem'), StackTrace.current, problem),
      );
      expect(
        await repository.choose(PhotoRole.body),
        Left<Failure, ChosenPhoto?>(PhotoFailure(problem)),
      );
    }
    // Only the photo that could not be read is an error worth logging.
    verify(
      logger.logError(
        callerClass: anyNamed('callerClass'),
        callerMethod: anyNamed('callerMethod'),
        error: anyNamed('error'),
        stackTrace: anyNamed('stackTrace'),
      ),
    ).called(1);
  });

  test('keeps a photo, or reports that it could not', () async {
    when(
      store.keep('/tmp/a.jpg', PhotoRole.body),
    ).thenAnswer((_) async => _body);
    expect(
      await repository.keep('/tmp/a.jpg', PhotoRole.body),
      const Right<Failure, UserPhoto>(_body),
    );
    when(
      store.keep(any, any),
    ).thenThrow(CacheException(Exception('disk full'), StackTrace.current));
    expect(
      await repository.keep('/tmp/a.jpg', PhotoRole.body),
      const Left<Failure, UserPhoto>(CacheFailure()),
    );
  });

  test('returns the kept photo, none, or a cache failure', () async {
    when(store.kept(PhotoRole.body)).thenReturn(_body);
    expect(
      await repository.kept(PhotoRole.body),
      const Right<Failure, UserPhoto?>(_body),
    );
    when(store.kept(PhotoRole.face)).thenReturn(null);
    expect(
      await repository.kept(PhotoRole.face),
      const Right<Failure, UserPhoto?>(null),
    );
    when(
      store.kept(any),
    ).thenThrow(CacheException(Exception('closed'), StackTrace.current));
    expect(
      await repository.kept(PhotoRole.body),
      const Left<Failure, UserPhoto?>(CacheFailure()),
    );
  });
}
