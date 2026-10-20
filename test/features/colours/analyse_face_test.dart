import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/account/domain/usecases/save_setup_to_account.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/repositories/analysis_job_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/colour_profile_repository.dart';
import 'package:in_vogue/features/colours/domain/repositories/skin_analysis_repository.dart';
import 'package:in_vogue/features/colours/domain/services/analyse_face.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analyse_face_test.mocks.dart';

const _face = UserPhoto(
  role: PhotoRole.face,
  path: '/photos/face-2.png',
  revision: 2,
);

const _colours = FaceColours(
  skin: '#E8C4AE',
  eyebrow: '#3B2A22',
  lip: '#C98276',
  hair: '#42280E',
  eye: '#5A3B2B',
  clear: true,
);

/// A service that answers with [answers], one check at a time.
class _Service implements SkinAnalysisRepository {
  _Service(this.answers);

  final List<AnalysisTask> answers;
  bool reachable = true;

  /// What every check answers instead, while set.
  Failure? checkFailure;
  final uploads = <String>[];
  final starts = <String>[];
  final checks = <String>[];
  final discarded = <String>[];

  @override
  bool get available => reachable;

  @override
  Future<Either<Failure, String>> uploadFace(String path) async {
    uploads.add(path);
    return const Right('file-1');
  }

  @override
  Future<Either<Failure, String>> start(String fileId) async {
    starts.add(fileId);
    return const Right('task-1');
  }

  @override
  Future<Either<Failure, AnalysisTask>> check(String taskId) async {
    checks.add(taskId);
    if (checkFailure case final failure?) return Left(failure);
    return Right(answers.removeAt(0));
  }

  @override
  Future<void> discard(String taskId) async => discarded.add(taskId);
}

class _Profiles implements ColourProfileRepository {
  final kept = <String, FaceColours>{};

  /// Keys in the order they were saved, the last one latest.
  final saved = <String>[];

  @override
  Future<Either<Failure, FaceColours?>> colours(
    String accountId,
    String facePhoto,
  ) async => Right(kept['$accountId$facePhoto']);

  @override
  Future<Either<Failure, FaceColours?>> latest(String accountId) async {
    final key = saved.lastWhere(
      (key) => key.startsWith(accountId),
      orElse: () => '',
    );
    return Right(kept[key]);
  }

  @override
  Future<Either<Failure, Unit>> save(
    String accountId,
    String facePhoto,
    FaceColours colours,
  ) async {
    kept['$accountId$facePhoto'] = colours;
    saved
      ..remove('$accountId$facePhoto')
      ..add('$accountId$facePhoto');
    return const Right(unit);
  }
}

class _Jobs implements AnalysisJobRepository {
  final tasks = <String, String>{};

  @override
  Future<String?> task(String key) async => tasks[key];

  @override
  Future<void> save(String key, String taskId) async => tasks[key] = taskId;

  @override
  Future<void> clear(String key) async => tasks.remove(key);

  @override
  Future<void> forgetAccount(String accountId) async => tasks.clear();
}

@GenerateMocks([PhotoRepository, SaveSetupToAccount])
void main() {
  late MockPhotoRepository photos;
  late MockSaveSetupToAccount saveSetup;
  late _Profiles profiles;
  late _Jobs jobs;

  setUp(() {
    provideDummy<Either<Failure, UserPhoto?>>(const Right(null));
    provideDummy<Either<Failure, Unit>>(const Right(unit));
    photos = MockPhotoRepository();
    saveSetup = MockSaveSetupToAccount();
    profiles = _Profiles();
    jobs = _Jobs();
    when(
      photos.kept(PhotoRole.face),
    ).thenAnswer((_) async => const Right(_face));
    when(saveSetup(any)).thenAnswer((_) async => const Right(unit));
  });

  AnalyseFace analyse(_Service service) => AnalyseFace(
    service: service,
    profiles: profiles,
    jobs: jobs,
    photos: photos,
    saveSetupToAccount: saveSetup,
    checkEvery: Duration.zero,
  );

  test('reads the face photo once: uploads it, waits for the colours and '
      'keeps them on the account', () async {
    final service = _Service([
      const AnalysisRunning(),
      const AnalysisDone(_colours),
    ]);
    expect(
      await analyse(service)('uid-1'),
      const Right<Failure, FaceColours>(_colours),
    );
    expect(service.uploads, [_face.path]);
    expect(service.starts, ['file-1']);
    expect(service.checks, ['task-1', 'task-1']);
    expect(profiles.kept['uid-1${_face.path}'], _colours);
    expect(jobs.tasks, isEmpty);
    expect(service.discarded, ['task-1']);
    // The face photo goes on the account first.
    verify(saveSetup('uid-1')).called(1);
  });

  test('takes the colours already read for the person, from any photo, '
      'and reads nothing', () async {
    await profiles.save('uid-1', '/photos/face-1.png', _colours);
    final service = _Service([]);
    expect(
      await analyse(service)('uid-1'),
      const Right<Failure, FaceColours>(_colours),
    );
    expect(service.uploads, isEmpty);
    verifyNever(photos.kept(any));
  });

  test(
    'a redo reads the current face photo and makes it the reading',
    () async {
      const older = FaceColours(
        skin: '#C69C82',
        eyebrow: '#4A3628',
        lip: '#B5726E',
        hair: '#4A3628',
        clear: true,
      );
      await profiles.save('uid-1', '/photos/face-1.png', older);
      final service = _Service([const AnalysisDone(_colours)]);
      expect(
        await analyse(service)('uid-1', redo: true),
        const Right<Failure, FaceColours>(_colours),
      );
      expect(service.uploads, [_face.path]);
      expect(
        await profiles.latest('uid-1'),
        const Right<Failure, FaceColours?>(_colours),
      );
    },
  );

  test('a redo of a photo read before takes its reading, for free', () async {
    await profiles.save('uid-1', _face.path, _colours);
    const later = FaceColours(
      skin: '#C69C82',
      eyebrow: '#4A3628',
      lip: '#B5726E',
      hair: '#4A3628',
      clear: true,
    );
    await profiles.save('uid-1', '/photos/face-3.png', later);
    final service = _Service([]);
    expect(
      await analyse(service)('uid-1', redo: true),
      const Right<Failure, FaceColours>(_colours),
    );
    expect(service.uploads, isEmpty);
    expect(
      await profiles.latest('uid-1'),
      const Right<Failure, FaceColours?>(_colours),
    );
  });

  test('picks up a reading cut short instead of paying for another', () async {
    jobs.tasks['uid-1/2'] = 'task-7';
    final service = _Service([const AnalysisDone(_colours)]);
    await analyse(service)('uid-1');
    expect(service.uploads, isEmpty);
    expect(service.checks, ['task-7']);
  });

  test('forgets a reading YouCam will not report on, so the next one starts '
      'anew', () async {
    jobs.tasks['uid-1/2'] = 'task-7';
    final service = _Service([const AnalysisDone(_colours)])
      ..checkFailure = const AnalysisFailure(AnalysisProblem.failed);
    expect(
      await analyse(service)('uid-1'),
      const Left<Failure, FaceColours>(AnalysisFailure(AnalysisProblem.failed)),
    );
    expect(jobs.tasks, isEmpty);
    service.checkFailure = null;
    expect(
      await analyse(service)('uid-1'),
      const Right<Failure, FaceColours>(_colours),
    );
    expect(service.uploads, hasLength(1));
    expect(service.checks, ['task-7', 'task-1']);
  });

  test('keeps a reading under way when the network fails', () async {
    jobs.tasks['uid-1/2'] = 'task-7';
    final service = _Service([])..checkFailure = const NetworkFailure();
    expect(
      await analyse(service)('uid-1'),
      const Left<Failure, FaceColours>(NetworkFailure()),
    );
    expect(jobs.tasks, {'uid-1/2': 'task-7'});
  });

  test('says what to change when the photo is refused, and starts again '
      'next time', () async {
    final service = _Service([
      const AnalysisFailed(
        AnalysisProblem.photo,
        advice: PhotoAdvice.lookStraight,
      ),
    ]);
    expect(
      await analyse(service)('uid-1'),
      const Left<Failure, FaceColours>(
        AnalysisFailure(
          AnalysisProblem.photo,
          advice: PhotoAdvice.lookStraight,
        ),
      ),
    );
    expect(jobs.tasks, isEmpty);
    expect(profiles.kept, isEmpty);
  });

  test('needs a face photo', () async {
    when(
      photos.kept(PhotoRole.face),
    ).thenAnswer((_) async => const Right(null));
    final service = _Service([]);
    expect(
      await analyse(service)('uid-1'),
      const Left<Failure, FaceColours>(AnalysisFailure(AnalysisProblem.photo)),
    );
    expect(service.uploads, isEmpty);
  });

  test('says when this build cannot read colours', () async {
    final service = _Service([])..reachable = false;
    expect(
      await analyse(service)('uid-1'),
      const Left<Failure, FaceColours>(
        AnalysisFailure(AnalysisProblem.unavailable),
      ),
    );
  });
}
