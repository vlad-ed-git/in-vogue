import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_model.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

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

    test('starts a task and reads how it stands', () async {
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
      expect(
        await youCam.start(YouCamTool.clothes, {'src_file_id': 'file-1'}),
        'task-1',
      );
      expect(
        await youCam.task(YouCamTool.clothes, 'task-1'),
        const YouCamTaskSucceeded({'url': 'https://results.example/r.jpg'}),
      );
    });

    test('calls each tool at its own path', () async {
      apiServer
        ..onPost(
          '/s2s/v2.0/task/makeup-vto',
          (server) => server.reply(200, {
            'data': {'task_id': 'makeup-1'},
          }),
          data: Matchers.any,
        )
        ..onGet(
          '/s2s/v2.0/task/skin-tone-analysis/skin-1',
          (server) => server.reply(200, {
            'data': {'task_status': 'running'},
          }),
        );
      expect(await youCam.start(YouCamTool.makeup, const {}), 'makeup-1');
      expect(
        await youCam.task(YouCamTool.skinTone, 'skin-1'),
        const YouCamTaskRunning(),
      );
    });

    test('names a refusal, which starts nothing', () async {
      apiServer.onPost(
        '/s2s/v2.0/task/cloth-v4',
        (server) => server.reply(400, {'error_code': 'CreditInsufficiency'}),
        data: Matchers.any,
      );
      await expectLater(
        youCam.start(YouCamTool.clothes, const {}),
        throwsA(
          isA<YouCamException>().having(
            (error) => error.problem,
            'problem',
            YouCamProblem.noCredit,
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
        youCam.task(YouCamTool.clothes, 'task-1'),
        throwsA(isA<NetworkException>()),
      );
    });
  });

  group('YouCamModel', () {
    test("reads the File API's upload request", () {
      final upload = YouCamModel.uploadOf({
        'status': 200,
        'data': {
          'files': [
            {
              'file_id': 'file-1',
              'requests': [
                {
                  'method': 'PUT',
                  'url': 'https://upload.example/put',
                  'headers': {'Content-Type': 'image/jpeg', 'Size': 3},
                },
              ],
            },
          ],
        },
      })!;
      expect(upload.fileId, 'file-1');
      expect(upload.url, 'https://upload.example/put');
      expect(upload.method, 'PUT');
      expect(upload.headers, {'Content-Type': 'image/jpeg', 'Size': '3'});
      expect(YouCamModel.uploadOf({'data': <String, Object?>{}}), isNull);
    });

    test('reads how a task stands', () {
      expect(
        YouCamModel.taskOf({
          'data': {'task_status': 'running'},
        }),
        const YouCamTaskRunning(),
      );
      expect(
        YouCamModel.taskOf({
          'data': {
            'task_status': 'success',
            'results': {'url': 'https://results.example/r.jpg'},
          },
        }),
        const YouCamTaskSucceeded({'url': 'https://results.example/r.jpg'}),
      );
    });

    test('finds a result URL wherever the answer puts it', () {
      expect(
        YouCamModel.resultUrl({'url': 'https://results.example/r.jpg'}),
        'https://results.example/r.jpg',
      );
      expect(
        YouCamModel.resultUrl([
          {'download_url': 'https://results.example/d.jpg'},
        ]),
        'https://results.example/d.jpg',
      );
      expect(YouCamModel.resultUrl(<String, Object?>{}), isNull);
    });

    test('tells a photo problem and a refused reference from a failure '
        'worth trying again', () {
      YouCamTask failed(String code) => YouCamModel.taskOf({
        'data': {'task_status': 'error', 'error': code},
      });
      expect(failed('error_pose'), const YouCamTaskFailed(YouCamProblem.photo));
      expect(
        failed('error_invalid_ref'),
        const YouCamTaskFailed(YouCamProblem.reference),
      );
      expect(
        failed('unknown_internal_error'),
        const YouCamTaskFailed(YouCamProblem.failed),
      );
    });

    test('names why a call was refused', () {
      expect(
        YouCamModel.refusal(400, {'error_code': 'CreditInsufficiency'}),
        YouCamProblem.noCredit,
      );
      expect(YouCamModel.refusal(401, null), YouCamProblem.unauthorized);
      expect(YouCamModel.refusal(500, null), YouCamProblem.failed);
    });
  });
}
