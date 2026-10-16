import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/data_sources/you_cam_remote_data_source.dart';
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
  group('YouCamRemoteDataSourceImpl', () {
    late Dio api;
    late Dio files;
    late DioAdapter apiServer;
    late DioAdapter fileServer;
    late YouCamRemoteDataSourceImpl youCam;

    setUp(() {
      api = Dio(BaseOptions(baseUrl: YouCamRemoteDataSourceImpl.baseUrl));
      files = Dio();
      apiServer = DioAdapter(dio: api);
      fileServer = DioAdapter(dio: files);
      youCam = YouCamRemoteDataSourceImpl(api: api, files: files);
    });

    test('uploads a photo through the File API, then to its URL', () async {
      apiServer.onPost(
        '/s2s/v2.0/file',
        (server) => server.reply(200, {
          'status': 200,
          'data': {
            'files': [
              {
                'file_id': 'file-1',
                'requests': [
                  {
                    'method': 'PUT',
                    'url': 'https://upload.example/put',
                    'headers': {'Content-Type': 'image/jpeg'},
                  },
                ],
              },
            ],
          },
        }),
        data: {
          'files': [
            {
              'content_type': 'image/jpeg',
              'file_name': 'body-1.jpg',
              'file_size': 3,
            },
          ],
        },
      );
      fileServer.onPut(
        'https://upload.example/put',
        (server) => server.reply(200, null),
        data: Matchers.any,
      );
      expect(
        await youCam.uploadFile(
          const [1, 2, 3],
          contentType: 'image/jpeg',
          name: 'body-1.jpg',
        ),
        'file-1',
      );
    });

    test('starts a clothes task and reads how it stands', () async {
      apiServer
        ..onPost(
          '/s2s/v2.0/task/cloth-v4',
          (server) => server.reply(200, {
            'data': {'task_id': 'task-1'},
          }),
          data: {'src_file_id': 'file-1'},
        )
        ..onGet(
          '/s2s/v2.0/task/cloth-v4/task-1',
          (server) => server.reply(200, {
            'data': {
              'task_status': 'success',
              'results': {'url': 'https://results.example/r.jpg'},
            },
          }),
        );
      expect(await youCam.startClothes({'src_file_id': 'file-1'}), 'task-1');
      expect(
        await youCam.clothesTask('task-1'),
        const TryOnSucceeded('https://results.example/r.jpg'),
      );
    });

    test('names a refusal, which starts nothing', () async {
      apiServer.onPost(
        '/s2s/v2.0/task/cloth-v4',
        (server) => server.reply(400, {'error_code': 'CreditInsufficiency'}),
        data: Matchers.any,
      );
      await expectLater(
        youCam.startClothes(const {}),
        throwsA(
          isA<YouCamException>().having(
            (error) => error.problem,
            'problem',
            TryOnProblem.budgetSpent,
          ),
        ),
      );
    });

    test('says when YouCam cannot be reached', () async {
      apiServer.onGet(
        '/s2s/v2.0/task/cloth-v4/task-1',
        (server) => server.throws(
          0,
          DioException.connectionError(
            requestOptions: RequestOptions(),
            reason: 'offline',
          ),
        ),
      );
      await expectLater(
        youCam.clothesTask('task-1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('TryOnRepositoryImpl', () {
    late MockYouCamRemoteDataSource remote;
    late TryOnRepositoryImpl repository;

    setUp(() {
      remote = MockYouCamRemoteDataSource();
      repository = TryOnRepositoryImpl(
        remoteDataSource: remote,
        logMessages: LogMessagesImpl(),
      );
      when(remote.startClothes(any)).thenAnswer((_) async => 'task-1');
    });

    test("keeps the person's shoes and dresses the main person", () async {
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Right<Failure, String>('task-1'),
      );
      verify(
        remote.startClothes({
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
          verify(remote.startClothes(captureAny)).captured.single
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
      when(remote.startClothes(any)).thenThrow(
        YouCamException(TryOnProblem.failed, Exception(), StackTrace.current),
      );
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Left<Failure, String>(TryOnFailure(TryOnProblem.failed)),
      );
      when(
        remote.startClothes(any),
      ).thenThrow(NetworkException(Exception(), StackTrace.current));
      expect(
        await repository.start(_coat, fileId: 'file-1'),
        const Left<Failure, String>(NetworkFailure()),
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
    expect(
      await repository.start(_coat, fileId: 'file-1'),
      const Left<Failure, String>(TryOnFailure(TryOnProblem.unavailable)),
    );
  });
}
