import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_check_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_picker_data_source.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_store_data_source.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:in_vogue/features/photos/data/repositories/photo_repository_impl.dart';
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
  PhotoCheckDataSource,
  PhotoStoreDataSource,
  PhotoRepository,
  LogMessages,
])
void main() {
  late MockPhotoPickerDataSource picker;
  late MockPhotoCheckDataSource check;
  late MockPhotoStoreDataSource store;
  late MockLogMessages logger;
  late PhotoRepositoryImpl repository;

  setUp(() {
    picker = MockPhotoPickerDataSource();
    check = MockPhotoCheckDataSource();
    store = MockPhotoStoreDataSource();
    logger = MockLogMessages();
    repository = PhotoRepositoryImpl(
      pickerDataSource: picker,
      checkDataSource: check,
      storeDataSource: store,
      logMessages: logger,
    );
  });

  PhotoException unreadable() =>
      PhotoException(PlatformException(code: 'unreadable'), StackTrace.current);

  test('returns the chosen photo, or none when the person cancels', () async {
    when(picker.choose()).thenAnswer((_) async => '/tmp/picked.jpg');
    expect(
      await repository.choose(),
      const Right<Failure, String?>('/tmp/picked.jpg'),
    );
    when(picker.choose()).thenAnswer((_) async => null);
    expect(await repository.choose(), const Right<Failure, String?>(null));
  });

  test('maps a picker problem to a photo failure and logs it', () async {
    final error = unreadable();
    when(picker.choose()).thenThrow(error);
    expect(
      await repository.choose(),
      const Left<Failure, String?>(PhotoFailure()),
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

  test('says whether a photo shows the person head to toe', () async {
    when(check.isFullLength('/tmp/a.jpg')).thenAnswer((_) async => true);
    when(check.isFullLength('/tmp/b.jpg')).thenAnswer((_) async => false);
    expect(
      await repository.isFullLength('/tmp/a.jpg'),
      const Right<Failure, bool>(true),
    );
    expect(
      await repository.isFullLength('/tmp/b.jpg'),
      const Right<Failure, bool>(false),
    );
  });

  test('maps a photo the check cannot read to a photo failure', () async {
    when(check.isFullLength(any)).thenThrow(unreadable());
    expect(
      await repository.isFullLength('/tmp/a.jpg'),
      const Left<Failure, bool>(PhotoFailure()),
    );
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
