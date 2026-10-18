import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/unavailable_try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'try_on_repository_test.mocks.dart';

const _coat = TryOnPass(
  category: GarmentCategory.outer,
  piece: 'everlane:coat',
  reference: 'https://cdn.example/coat.jpg',
);

@GenerateMocks([YouCamRemoteDataSource])
void main() {
  group('TryOnRepositoryImpl', () {
    late MockYouCamRemoteDataSource remote;
    late TryOnRepositoryImpl repository;

    setUp(() {
      provideDummy<YouCamTask>(const YouCamTaskRunning());
      remote = MockYouCamRemoteDataSource();
      repository = TryOnRepositoryImpl(
        remoteDataSource: remote,
        logMessages: LogMessagesImpl(),
      );
      when(remote.start(any, any)).thenAnswer((_) async => 'task-1');
    });

    test("keeps the person's shoes and dresses the main person", () async {
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Right<Failure, String>('task-1'),
      );
      verify(
        remote.start(YouCamTool.clothes, {
          'src_file_id': 'file-1',
          'ref_file_url': 'https://cdn.example/coat.jpg',
          'garment_category': 'outer',
          'change_shoes': false,
          'filter_multi_person': 'normal',
        }),
      ).called(1);
    });

    test('dresses the previous pass from its picture', () async {
      await repository.start(_coat, pictureUrl: 'https://r/task-0');
      final params =
          verify(remote.start(any, captureAny)).captured.single
              as Map<String, Object?>;
      expect(params['src_file_url'], 'https://r/task-0');
      expect(params, isNot(contains('src_file_id')));
    });

    test('uploads the photo with its type', () async {
      final directory = await Directory.systemTemp.createTemp('try_on');
      addTearDown(() => directory.delete(recursive: true));
      final photo = File('${directory.path}/body-2.png')
        ..writeAsBytesSync(const [1, 2]);
      when(
        remote.uploadFile(
          any,
          contentType: anyNamed('contentType'),
          name: anyNamed('name'),
        ),
      ).thenAnswer((_) async => 'file-2');
      expect(
        await repository.upload(photo.path),
        const Right<Failure, String>('file-2'),
      );
      verify(
        remote.uploadFile(
          const [1, 2],
          contentType: 'image/png',
          name: 'body-2.png',
        ),
      ).called(1);
    });

    test('tells a refusal from an unknown outcome', () async {
      when(remote.start(any, any)).thenThrow(
        YouCamException(YouCamProblem.failed, Exception(), StackTrace.current),
      );
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Left<Failure, String>(TryOnFailure(TryOnProblem.failed)),
      );
      when(
        remote.start(any, any),
      ).thenThrow(NetworkException(Exception(), StackTrace.current));
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Left<Failure, String>(NetworkFailure()),
      );
    });

    test("names YouCam's problems as try-on problems", () async {
      when(remote.start(any, any)).thenThrow(
        YouCamException(
          YouCamProblem.noCredit,
          Exception(),
          StackTrace.current,
        ),
      );
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Left<Failure, String>(TryOnFailure(TryOnProblem.noCredit)),
      );
      when(remote.start(any, any)).thenThrow(
        YouCamException(
          YouCamProblem.unauthorized,
          Exception(),
          StackTrace.current,
        ),
      );
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Left<Failure, String>(TryOnFailure(TryOnProblem.unavailable)),
      );
    });

    test('reads a finished task as its picture', () async {
      when(remote.task(YouCamTool.clothes, 'task-1')).thenAnswer(
        (_) async =>
            const YouCamTaskSucceeded({'url': 'https://results.example/r.jpg'}),
      );
      expect(
        await repository.check('task-1'),
        const Right<Failure, TryOnTask>(
          TryOnSucceeded('https://results.example/r.jpg'),
        ),
      );
      when(
        remote.task(YouCamTool.clothes, 'task-2'),
      ).thenAnswer((_) async => const YouCamTaskSucceeded(<String, Object?>{}));
      expect(
        await repository.check('task-2'),
        const Right<Failure, TryOnTask>(TryOnErrored(TryOnProblem.failed)),
      );
      when(remote.task(YouCamTool.clothes, 'task-3')).thenAnswer(
        (_) async => const YouCamTaskFailed(
          YouCamProblem.photo,
          advice: PhotoAdvice.onlyYou,
          code: 'error_multi_person',
        ),
      );
      expect(
        await repository.check('task-3'),
        const Right<Failure, TryOnTask>(
          TryOnErrored(TryOnProblem.photo, advice: PhotoAdvice.onlyYou),
        ),
      );
      when(remote.task(YouCamTool.clothes, 'task-4')).thenAnswer(
        (_) async => const YouCamTaskFailed(YouCamProblem.reference),
      );
      expect(
        await repository.check('task-4'),
        const Right<Failure, TryOnTask>(TryOnErrored(TryOnProblem.reference)),
      );
    });

    test('says the photo is the problem when it cannot be read', () async {
      expect(
        await repository.upload('/no/such/body-1.jpg'),
        const Left<Failure, String>(TryOnFailure(TryOnProblem.photo)),
      );
    });
  });

  test('a build without the try-on service makes no outfits', () async {
    const repository = UnavailableTryOnRepository();
    expect(repository.available, isFalse);
    expect(
      await repository.start(_coat, fileId: 'file-1'),
      const Left<Failure, String>(TryOnFailure(TryOnProblem.unavailable)),
    );
  });
}
