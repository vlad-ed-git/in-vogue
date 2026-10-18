import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/domain/errors/log_messages.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/colours/data/data_sources/face_picture_data_source.dart';
import 'package:in_vogue/features/colours/data/repositories/skin_analysis_repository_impl.dart';
import 'package:in_vogue/features/colours/data/repositories/unavailable_skin_analysis_repository.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/repositories/skin_analysis_repository.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:mockito/mockito.dart';

import '../outfits/try_on_repository_test.mocks.dart';

/// Keeps what is logged.
class _Log implements LogMessages {
  final errors = <String>[];

  @override
  void logError({
    required String callerClass,
    required String callerMethod,
    required Object error,
    StackTrace? stackTrace,
  }) => errors.add('$callerClass.$callerMethod: $error');
}

class _FakeFaces implements FacePictureDataSource {
  bool unreadable = false;

  @override
  Future<List<int>> prepare(String path) async {
    if (unreadable) throw PhotoException(Exception(), StackTrace.current);
    return const [0x89, 0x50, 0x4E, 0x47];
  }
}

void main() {
  late MockYouCamRemoteDataSource remote;
  late _FakeFaces faces;
  late _Log log;
  late SkinAnalysisRepositoryImpl service;

  setUp(() {
    provideDummy<YouCamTask>(const YouCamTaskRunning());
    remote = MockYouCamRemoteDataSource();
    faces = _FakeFaces();
    log = _Log();
    service = SkinAnalysisRepositoryImpl(
      remoteDataSource: remote,
      faceDataSource: faces,
      logMessages: log,
    );
    when(remote.start(any, any)).thenAnswer((_) async => 'task-1');
    when(
      remote.uploadFile(
        any,
        contentType: anyNamed('contentType'),
        name: anyNamed('name'),
      ),
    ).thenAnswer((_) async => 'file-1');
  });

  test('puts the face on the service upright and small, as a PNG', () async {
    expect(
      await service.uploadFace('/support/photos/face-1.jpg'),
      const Right<Failure, String>('file-1'),
    );
    verify(
      remote.uploadFile(
        const [0x89, 0x50, 0x4E, 0x47],
        contentType: 'image/png',
        name: 'face.png',
      ),
    ).called(1);
  });

  test('says the photo is the problem when it cannot be read', () async {
    faces.unreadable = true;
    expect(
      await service.uploadFace('/support/photos/face-1.jpg'),
      const Left<Failure, String>(AnalysisFailure(AnalysisProblem.photo)),
    );
  });

  test(
    'analyses the face at low angle strictness, trusting the photo',
    () async {
      expect(
        await service.start('file-1'),
        const Right<Failure, String>('task-1'),
      );
      verify(
        remote.start(YouCamTool.skinTone, {
          'src_file_id': 'file-1',
          'face_angle_strictness_level': 'low',
        }),
      ).called(1);
    },
  );

  test("reads a finished analysis's colours, eyes included", () async {
    when(remote.task(YouCamTool.skinTone, 'task-1')).thenAnswer(
      (_) async => const YouCamTaskSucceeded({
        'color': {
          'skin_color': '#e8c4ae',
          'eyebrow_color': '#3B2A22',
          'lip_color': '#C98276',
          'hair_color': '#42280E',
          'eye_color': '#5A3B2B',
        },
      }),
    );
    expect(
      await service.check('task-1'),
      const Right<Failure, AnalysisTask>(
        AnalysisDone(
          FaceColours(
            skin: '#E8C4AE',
            eyebrow: '#3B2A22',
            lip: '#C98276',
            hair: '#42280E',
            eye: '#5A3B2B',
            clear: true,
          ),
        ),
      ),
    );
  });

  test('logs a failed task with its code and keeps what to change', () async {
    when(remote.task(YouCamTool.skinTone, 'task-1')).thenAnswer(
      (_) async => const YouCamTaskFailed(
        YouCamProblem.photo,
        advice: PhotoAdvice.lookStraight,
        code: 'error_face_angle_rightward',
      ),
    );
    expect(
      await service.check('task-1'),
      const Right<Failure, AnalysisTask>(
        AnalysisFailed(AnalysisProblem.photo, advice: PhotoAdvice.lookStraight),
      ),
    );
    expect(log.errors, [contains('error_face_angle_rightward')]);
  });

  test("names YouCam's refusals as analysis problems", () async {
    final quiet = SkinAnalysisRepositoryImpl(
      remoteDataSource: remote,
      faceDataSource: faces,
      logMessages: LogMessagesImpl(),
    );
    when(remote.start(any, any)).thenThrow(
      YouCamException(YouCamProblem.noCredit, Exception(), StackTrace.current),
    );
    expect(
      await quiet.start('file-1'),
      const Left<Failure, String>(AnalysisFailure(AnalysisProblem.noCredit)),
    );
    when(
      remote.task(YouCamTool.skinTone, 'task-1'),
    ).thenThrow(NetworkException(Exception(), StackTrace.current));
    expect(
      await quiet.check('task-1'),
      const Left<Failure, AnalysisTask>(NetworkFailure()),
    );
  });

  test('a build without the service reads nothing', () async {
    const unavailable = UnavailableSkinAnalysisRepository();
    expect(unavailable.available, isFalse);
    expect(
      await unavailable.uploadFace('/support/photos/face-1.jpg'),
      const Left<Failure, String>(AnalysisFailure(AnalysisProblem.unavailable)),
    );
  });
}
