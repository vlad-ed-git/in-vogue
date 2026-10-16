import 'package:dio/dio.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/models/you_cam_model.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';

/// YouCam refused a call; nothing it was asked to start has started.
class YouCamException implements Exception {
  const YouCamException(this.problem, this.cause, this.stackTrace);

  final TryOnProblem problem;
  final Object cause;
  final StackTrace stackTrace;
}

/// YouCam's AI Clothes (cloth-v4) and File APIs.
///
/// Every method throws [YouCamException] when YouCam refuses and
/// [NetworkException] when it cannot be reached.
abstract interface class YouCamRemoteDataSource {
  /// Uploads [bytes] through the File API; the file's id.
  Future<String> uploadFile(
    List<int> bytes, {
    required String contentType,
    required String name,
  });

  /// Starts a clothes task with [params]; its id.
  Future<String> startClothes(Map<String, Object?> params);

  /// How the clothes task [taskId] stands.
  Future<TryOnTask> clothesTask(String taskId);

  /// The file at [url].
  Future<List<int>> download(String url);

  /// Deletes the task [taskId] and its files.
  Future<void> deleteTask(String taskId);
}

class YouCamRemoteDataSourceImpl implements YouCamRemoteDataSource {
  /// [api] carries the base URL and the API key; [files] has neither, for
  /// YouCam's upload and result URLs.
  YouCamRemoteDataSourceImpl({required this._api, required this._files});

  final Dio _api;
  final Dio _files;

  static const baseUrl = 'https://yce-api-01.makeupar.com';

  static const _clothes = '/s2s/v2.0/task/cloth-v4';

  @override
  Future<String> uploadFile(
    List<int> bytes, {
    required String contentType,
    required String name,
  }) => _guard(() async {
    final answer = await _api.post<Object?>(
      '/s2s/v2.0/file',
      data: {
        'files': [
          {
            'content_type': contentType,
            'file_name': name,
            'file_size': bytes.length,
          },
        ],
      },
    );
    final upload = YouCamModel.uploadOf(answer.data);
    if (upload == null) {
      throw YouCamException(
        TryOnProblem.failed,
        const FormatException('No upload request'),
        StackTrace.current,
      );
    }
    await _files.request<void>(
      upload.url,
      data: Stream<List<int>>.value(bytes),
      options: Options(
        method: upload.method,
        headers: {...upload.headers, Headers.contentLengthHeader: bytes.length},
      ),
    );
    return upload.fileId;
  });

  @override
  Future<String> startClothes(Map<String, Object?> params) => _guard(() async {
    final answer = await _api.post<Object?>(_clothes, data: params);
    final taskId = YouCamModel.taskIdOf(answer.data);
    if (taskId == null) {
      throw YouCamException(
        TryOnProblem.failed,
        const FormatException('No task id'),
        StackTrace.current,
      );
    }
    return taskId;
  });

  @override
  Future<TryOnTask> clothesTask(String taskId) => _guard(() async {
    final answer = await _api.get<Object?>(
      '$_clothes/${Uri.encodeComponent(taskId)}',
    );
    return YouCamModel.taskOf(answer.data);
  });

  @override
  Future<List<int>> download(String url) => _guard(() async {
    final answer = await _files.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return answer.data ?? const [];
  });

  @override
  Future<void> deleteTask(String taskId) => _guard(
    () =>
        _api.post<Object?>('/s2s/v2.0/task/delete', data: {'task_id': taskId}),
  );

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (error, stack) {
      final response = error.response;
      if (response == null) throw NetworkException(error, stack);
      throw YouCamException(
        YouCamModel.refusal(response.statusCode ?? 0, response.data),
        error,
        stack,
      );
    }
  }
}
