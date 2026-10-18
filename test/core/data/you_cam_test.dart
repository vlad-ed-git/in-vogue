import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_model.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
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
      expect(
        failed('error_decode_image'),
        const YouCamTaskFailed(YouCamProblem.photo, code: 'error_decode_image'),
      );
      expect(
        failed('error_invalid_ref'),
        const YouCamTaskFailed(
          YouCamProblem.reference,
          code: 'error_invalid_ref',
        ),
      );
      expect(
        failed('unknown_internal_error'),
        const YouCamTaskFailed(
          YouCamProblem.failed,
          code: 'unknown_internal_error',
        ),
      );
    });

    test('says what to change in a photo the engine refused', () {
      YouCamTask failed(String code) => YouCamModel.taskOf({
        'data': {'task_status': 'error', 'error': code},
      });
      for (final code in [
        'error_face_angle_invalid',
        'error_face_not_forward_facing',
        'error_face_angle_upward',
        'error_face_angle_downward',
        'error_face_angle_leftward',
        'error_face_angle_rightward',
        'error_face_angle_left_tilt',
        'error_face_angle_right_tilt',
      ]) {
        expect(
          failed(code),
          YouCamTaskFailed(
            YouCamProblem.photo,
            advice: PhotoAdvice.lookStraight,
            code: code,
          ),
          reason: code,
        );
      }
      PhotoAdvice? adviceFor(String code) => switch (failed(code)) {
        YouCamTaskFailed(:final advice) => advice,
        _ => null,
      };
      expect(
        adviceFor('error_face_position_too_small'),
        PhotoAdvice.moveCloser,
      );
      expect(
        adviceFor('error_face_position_out_of_boundary'),
        PhotoAdvice.showWholeFace,
      );
      expect(
        adviceFor('error_face_position_invalid'),
        PhotoAdvice.showWholeFace,
      );
      expect(adviceFor('error_multi_person'), PhotoAdvice.onlyYou);
      expect(adviceFor('error_pose'), PhotoAdvice.standHeadToToe);
      expect(adviceFor('error_decode_image'), isNull);
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
