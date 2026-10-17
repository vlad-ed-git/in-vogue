import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_model.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';

/// YouCam's AI tools, by the path of their tasks.
enum YouCamTool {
  /// AI Clothes.
  clothes('cloth-v4'),

  /// Makeup VTO.
  makeup('makeup-vto'),

  /// Facial Color Tones Analyzer.
  skinTone('skin-tone-analysis');

  const YouCamTool(this.path);
  final String path;
}

/// Why YouCam refused a call or failed a task.
enum YouCamProblem {
  /// Trying again may work.
  failed,

  /// The engine could not use the photo.
  photo,

  /// The engine could not use the reference photo; another may work.
  reference,

  /// The account's units are spent.
  noCredit,

  /// The API key was refused.
  unauthorized,
}

/// YouCam refused a call; nothing it was asked to start has started.
class YouCamException implements Exception {
  const YouCamException(this.problem, this.cause, this.stackTrace);

  final YouCamProblem problem;
  final Object cause;
  final StackTrace stackTrace;
}

/// How a YouCam task stands.
sealed class YouCamTask extends Equatable {
  const YouCamTask();

  @override
  List<Object?> get props => [];
}

final class YouCamTaskRunning extends YouCamTask {
  const YouCamTaskRunning();
}

/// Finished, with the tool's [results].
final class YouCamTaskSucceeded extends YouCamTask {
  const YouCamTaskSucceeded(this.results);
  final Object? results;

  @override
  List<Object?> get props => [results];
}

/// Failed; YouCam charges nothing for it.
final class YouCamTaskFailed extends YouCamTask {
  const YouCamTaskFailed(this.problem);
  final YouCamProblem problem;

  @override
  List<Object?> get props => [problem];
}

/// YouCam's task and File APIs.
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

  /// Starts a [tool] task with [params]; its id.
  Future<String> start(YouCamTool tool, Map<String, Object?> params);

  /// How the [tool] task [taskId] stands.
  Future<YouCamTask> task(YouCamTool tool, String taskId);

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

  static String _tasks(YouCamTool tool) => '/s2s/v2.0/task/${tool.path}';

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
        YouCamProblem.failed,
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
  Future<String> start(YouCamTool tool, Map<String, Object?> params) =>
      _guard(() async {
        final answer = await _api.post<Object?>(_tasks(tool), data: params);
        final taskId = YouCamModel.taskIdOf(answer.data);
        if (taskId == null) {
          throw YouCamException(
            YouCamProblem.failed,
            const FormatException('No task id'),
            StackTrace.current,
          );
        }
        return taskId;
      });

  @override
  Future<YouCamTask> task(YouCamTool tool, String taskId) => _guard(() async {
    final answer = await _api.get<Object?>(
      '${_tasks(tool)}/${Uri.encodeComponent(taskId)}',
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
