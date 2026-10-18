import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';

void main() {
  group('an error report names', () {
    test("a Firebase error's plugin and code", () {
      expect(
        LogMessagesImpl.categoryOf(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
        ),
        'FirebaseException cloud_firestore/unavailable',
      );
    });

    test("YouCam's code for a failed task", () {
      expect(
        LogMessagesImpl.categoryOf(
          const YouCamTaskError('error_face_angle_rightward'),
        ),
        'YouCamTaskError error_face_angle_rightward',
      );
    });

    test('the kind of a network failure', () {
      expect(
        LogMessagesImpl.categoryOf(
          DioException(
            requestOptions: RequestOptions(),
            type: DioExceptionType.connectionTimeout,
          ),
        ),
        'DioException connectionTimeout',
      );
    });

    test('only the kind of anything else, never its message', () {
      expect(
        LogMessagesImpl.categoryOf(const FormatException('maya@example.com')),
        'FormatException',
      );
    });
  });
}
