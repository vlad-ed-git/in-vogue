import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/data/you_cam/you_cam_remote_data_source.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/makeup/data/data_sources/face_picture_data_source.dart';
import 'package:in_vogue/features/makeup/data/repositories/makeup_service_repository_impl.dart';
import 'package:in_vogue/features/makeup/data/repositories/unavailable_makeup_service_repository.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_service_repository.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:mockito/mockito.dart';

import '../outfits/try_on_repository_test.mocks.dart';

const _effects = [
  {'category': 'skin_smooth', 'skinSmoothStrength': 0},
  {
    'category': 'blush',
    'palettes': [
      {'color': '#E6A0A6'},
    ],
  },
];

void main() {
  late MockYouCamRemoteDataSource remote;
  late _FakeFaces faces;
  late MakeupServiceRepositoryImpl service;

  setUp(() {
    provideDummy<YouCamTask>(const YouCamTaskRunning());
    remote = MockYouCamRemoteDataSource();
    faces = _FakeFaces();
    service = MakeupServiceRepositoryImpl(
      remoteDataSource: remote,
      faceDataSource: faces,
      logMessages: LogMessagesImpl(),
    );
    when(remote.start(any, any)).thenAnswer((_) async => 'task-1');
  });

  test('analyses a face held within ten degrees of the camera', () async {
    expect(
      await service.startAnalysis('file-1'),
      const Right<Failure, String>('task-1'),
    );
    verify(
      remote.start(YouCamTool.skinTone, {
        'src_file_id': 'file-1',
        'face_angle_strictness_level': 'high',
      }),
    ).called(1);
  });

  test("reads a finished analysis's colours", () async {
    when(remote.task(YouCamTool.skinTone, 'task-1')).thenAnswer(
      (_) async => const YouCamTaskSucceeded({
        'face_quality': {
          'has_face': true,
          'frontal': 'good',
          'lighting': 'good',
          'faceangle': 'good',
        },
        'color': {
          'skin_color': '#E8C4AE',
          'eyebrow_color': '#3B2A22',
          'lip_color': '#C98276',
          'hair_color': '#42280E',
        },
      }),
    );
    expect(
      await service.checkAnalysis('task-1'),
      const Right<Failure, MakeupTask<FaceColours>>(
        MakeupTaskDone(
          FaceColours(
            skin: '#E8C4AE',
            eyebrow: '#3B2A22',
            lip: '#C98276',
            hair: '#42280E',
            clear: true,
          ),
        ),
      ),
    );
  });

  test("renders a step's effects on the uploaded face", () async {
    await service.startStep('file-2', _effects);
    verify(
      remote.start(YouCamTool.makeup, {
        'src_file_id': 'file-2',
        'version': '1.0',
        'effects': _effects,
      }),
    ).called(1);
  });

  test('reads a finished step as its picture, and none as a failure', () async {
    when(remote.task(YouCamTool.makeup, 'task-1')).thenAnswer(
      (_) async =>
          const YouCamTaskSucceeded({'url': 'https://results.example/s.jpg'}),
    );
    when(
      remote.task(YouCamTool.makeup, 'task-2'),
    ).thenAnswer((_) async => const YouCamTaskSucceeded(<String, Object?>{}));
    expect(
      await service.checkStep('task-1'),
      const Right<Failure, MakeupTask<String>>(
        MakeupTaskDone('https://results.example/s.jpg'),
      ),
    );
    expect(
      await service.checkStep('task-2'),
      const Right<Failure, MakeupTask<String>>(
        MakeupTaskFailed(MakeupProblem.failed),
      ),
    );
  });

  test("names YouCam's problems as makeup problems", () async {
    when(remote.start(any, any)).thenThrow(
      YouCamException(YouCamProblem.noCredit, Exception(), StackTrace.current),
    );
    expect(
      await service.startStep('file-2', _effects),
      const Left<Failure, String>(MakeupFailure(MakeupProblem.noCredit)),
    );
    when(
      remote.task(YouCamTool.skinTone, 'task-1'),
    ).thenAnswer((_) async => const YouCamTaskFailed(YouCamProblem.photo));
    expect(
      await service.checkAnalysis('task-1'),
      const Right<Failure, MakeupTask<FaceColours>>(
        MakeupTaskFailed(MakeupProblem.photo),
      ),
    );
    when(
      remote.task(YouCamTool.makeup, 'task-1'),
    ).thenThrow(NetworkException(Exception(), StackTrace.current));
    expect(
      await service.checkStep('task-1'),
      const Left<Failure, MakeupTask<String>>(NetworkFailure()),
    );
  });

  test('says the photo is the problem when it cannot be read', () async {
    faces.unreadable = true;
    expect(
      await service.prepareFace('/support/photos/face-1.jpg'),
      const Left<Failure, List<int>>(MakeupFailure(MakeupProblem.photo)),
    );
  });

  test('a build without the service makes no makeup', () async {
    const unavailable = UnavailableMakeupServiceRepository();
    expect(unavailable.available, isFalse);
    expect(
      await unavailable.startStep('file-1', _effects),
      const Left<Failure, String>(MakeupFailure(MakeupProblem.unavailable)),
    );
  });
}

class _FakeFaces implements FacePictureDataSource {
  bool unreadable = false;

  @override
  Future<List<int>> prepare(String path) async {
    if (unreadable) throw PhotoException(Exception(), StackTrace.current);
    return const [0x89, 0x50, 0x4E, 0x47];
  }
}
