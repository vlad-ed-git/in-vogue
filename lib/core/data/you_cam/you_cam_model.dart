import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';

/// Where YouCam's File API takes a file's bytes.
typedef YouCamUpload = ({
  String fileId,
  String url,
  String method,
  Map<String, String> headers,
});

/// Reads YouCam's answers (docs.perfectcorp.com, API v2.0).
abstract final class YouCamModel {
  /// Engine errors caused by the person's photo; trying again won't help.
  static const photoErrors = {
    'error_no_face',
    'error_src_no_face',
    'error_face_position_invalid',
    'error_face_position_too_small',
    'error_face_position_out_of_boundary',
    'error_face_angle_invalid',
    'error_face_not_forward_facing',
    'error_face_angle_upward',
    'error_face_angle_downward',
    'error_face_angle_leftward',
    'error_face_angle_rightward',
    'error_face_angle_left_tilt',
    'error_face_angle_right_tilt',
    'error_face_parsing',
    'error_pose',
    'error_invalid_src',
    'error_apply_region_mismatch',
    'error_multi_person',
    'error_below_min_image_size',
    'error_exceed_max_image_size',
    'exceed_max_filesize',
    'error_decode_image',
    'error_nsfw_content_detected',
  };

  /// What to change about the photo for the [photoErrors] that say.
  static const photoAdvice = {
    'error_face_angle_invalid': PhotoAdvice.lookStraight,
    'error_face_not_forward_facing': PhotoAdvice.lookStraight,
    'error_face_angle_upward': PhotoAdvice.lookStraight,
    'error_face_angle_downward': PhotoAdvice.lookStraight,
    'error_face_angle_leftward': PhotoAdvice.lookStraight,
    'error_face_angle_rightward': PhotoAdvice.lookStraight,
    'error_face_angle_left_tilt': PhotoAdvice.lookStraight,
    'error_face_angle_right_tilt': PhotoAdvice.lookStraight,
    'error_face_position_too_small': PhotoAdvice.moveCloser,
    'error_face_position_out_of_boundary': PhotoAdvice.showWholeFace,
    'error_face_position_invalid': PhotoAdvice.showWholeFace,
    'error_multi_person': PhotoAdvice.onlyYou,
    'error_pose': PhotoAdvice.standHeadToToe,
    'error_apply_region_mismatch': PhotoAdvice.standHeadToToe,
  };

  /// Engine errors caused by the reference photo.
  static const referenceErrors = {'error_invalid_ref'};

  /// The `data` object of an answer; empty when there is none.
  static Map<String, Object?> dataOf(Object? body) => switch (body) {
    {'data': final Map<String, Object?> data} => data,
    _ => const {},
  };

  /// The first file's id and upload request; null when the answer has none.
  static YouCamUpload? uploadOf(Object? body) {
    if (dataOf(body) case {
      'files': [
        {
          'file_id': final String fileId,
          'requests': [
            {'url': final String url} && final Map<String, Object?> request,
            ...,
          ],
        },
        ...,
      ],
    }) {
      return (
        fileId: fileId,
        url: url,
        method: switch (request['method']) {
          final String method => method,
          _ => 'PUT',
        },
        headers: switch (request['headers']) {
          final Map<String, Object?> headers => {
            for (final MapEntry(:key, :value) in headers.entries) key: '$value',
          },
          _ => const {},
        },
      );
    }
    return null;
  }

  /// The started task's id; null when the answer has none.
  static String? taskIdOf(Object? body) => switch (dataOf(body)) {
    {'task_id': final String taskId} => taskId,
    _ => null,
  };

  /// How a task stands.
  static YouCamTask taskOf(Object? body) {
    final data = dataOf(body);
    return switch (data['task_status']) {
      'success' => YouCamTaskSucceeded(data['results']),
      'error' => YouCamTaskFailed(
        switch (data['error']) {
          final Object error when photoErrors.contains(error) =>
            YouCamProblem.photo,
          final Object error when referenceErrors.contains(error) =>
            YouCamProblem.reference,
          _ => YouCamProblem.failed,
        },
        advice: photoAdvice[data['error']],
        code: switch (data['error']) {
          final Object error => '$error',
          null => null,
        },
      ),
      _ => const YouCamTaskRunning(),
    };
  }

  /// The result's URL wherever the answer puts it: `url`, `download_url`,
  /// or deeper in a list or object.
  static String? resultUrl(Object? results, [int depth = 0]) {
    if (depth > 4) return null;
    switch (results) {
      case final List<Object?> items:
        for (final item in items) {
          final url = resultUrl(item, depth + 1);
          if (url != null) return url;
        }
      case final Map<String, Object?> fields:
        for (final name in const ['url', 'download_url']) {
          if (fields[name] case final String url) return url;
        }
        for (final value in fields.values) {
          final url = resultUrl(value, depth + 1);
          if (url != null) return url;
        }
    }
    return null;
  }

  /// The problem behind a refused call with HTTP [status] and the answer's
  /// [body].
  static YouCamProblem refusal(int status, Object? body) {
    final code = switch (body) {
      {'error_code': final Object code} => '$code',
      _ => '',
    };
    if (code == 'CreditInsufficiency') return YouCamProblem.noCredit;
    if (status == 401) return YouCamProblem.unauthorized;
    return YouCamProblem.failed;
  }
}
