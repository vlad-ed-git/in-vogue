import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_job_local_data_source.dart';
import 'package:in_vogue/features/makeup/data/repositories/makeup_job_repository_impl.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_job.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_update.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_service_repository.dart';
import 'package:in_vogue/features/makeup/domain/services/make_look.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/memory_store.dart';
import '../auth/sign_in_bloc_test.mocks.dart';

const _signature = 'coat+tee';
final _outfit = DayOutfit(
  outfit: const Outfit(
    id: 'o1',
    signature: _signature,
    pieces: ['everlane:tee', 'everlane:coat'],
    passes: [],
    palette: OutfitPalette.coolNeutral,
  ),
  date: DateTime.utc(2026, 10, 17),
  occasion: Occasion.work,
  cell: 'cool|wet|calm|work',
  picture: '/support/outfits/uid-1/coat+tee.jpg',
);
final _params = MakeLookParams(
  accountId: 'uid-1',
  outfit: _outfit,
  weather: const WeatherClass(
    band: WarmthBand.cool,
    precipitation: Precipitation.wet,
    windy: false,
  ),
);
const _face = UserPhoto(
  role: PhotoRole.face,
  path: '/support/photos/face-1.jpg',
  revision: 1,
);

/// What the analysis finds: light skin, high contrast.
const _colours = FaceColours(
  skin: '#E8C4AE',
  eyebrow: '#3B2A22',
  lip: '#C98276',
  hair: '#42280E',
  clear: true,
);
const _neutralKey = 'work|cool_neutral|medium|medium|rain';
const _matchedKey = 'work|cool_neutral|light|high|rain';

MakeupRecipe _recipe(String key) => MakeupRecipe(
  key: key,
  cheeks: CheekColour.rose,
  lips: LipColour.rosyNude,
  steps: const [
    RecipeStep(
      title: 'Even base',
      howTo: 'Blend it in.',
      products: ['foundation in your shade'],
      effects: [
        {
          'category': 'foundation',
          'palettes': [
            {'color': '{skin}'},
          ],
        },
      ],
    ),
    RecipeStep(
      title: 'Brows',
      howTo: 'Fill them in.',
      products: ['brow pencil'],
      effects: [
        {
          'category': 'eyebrows',
          'palettes': [
            {'color': '{brow}'},
          ],
        },
      ],
    ),
    RecipeStep(
      title: 'Lips',
      howTo: 'Last of all.',
      products: ['lipstick'],
      effects: [
        {
          'category': 'lip_color',
          'palettes': [
            {'color': '{nudeLip}'},
          ],
        },
      ],
    ),
  ],
);

const _before = '/phone/coat+tee/before.png';
String _step(int number) => '/phone/coat+tee/step-$number.jpg';

void main() {
  late _FakeLooks looks;
  late _FakeService service;
  late MemoryStore store;
  late MakeupJobRepositoryImpl jobs;
  late _FakePhotos photos;
  late MockSaveSetupToAccount saveSetup;

  MakeLook makeLook({Duration taskTimeLimit = const Duration(minutes: 2)}) =>
      MakeLook(
        looks: looks,
        service: service,
        jobs: jobs,
        photos: photos,
        saveSetupToAccount: saveSetup,
        checkEvery: Duration.zero,
        taskTimeLimit: taskTimeLimit,
      );

  Future<List<MakeupUpdate>> make([MakeLook? maker, MakeLookParams? params]) =>
      (maker ?? makeLook())(params ?? _params).toList();

  MakeupJob? keptJob() =>
      MakeupJobLocalDataSourceImpl(store).jobs()[_params.key];

  setUp(() {
    looks = _FakeLooks();
    service = _FakeService();
    store = MemoryStore();
    jobs = MakeupJobRepositoryImpl(MakeupJobLocalDataSourceImpl(store));
    photos = _FakePhotos();
    saveSetup = MockSaveSetupToAccount();
    when(saveSetup(any)).thenAnswer((_) async => const Right(unit));
  });

  test(
    'analyses the face, then renders each step on the last picture',
    () async {
      final updates = await make();
      expect(updates.whereType<MakeupProgress>().map(_made), [
        [false, false, false],
        [false, false, false],
        [true, false, false],
        [true, true, false],
        [true, true, true],
      ]);
      expect(updates.last, isA<MakeupDone>());
      expect(service.uploads, [_before, _before, _step(1), _step(2)]);
      expect(service.analyses, ['file-1']);
      expect(
        [for (final start in service.steps) start.fileId],
        ['file-2', 'file-3', 'file-4'],
      );
      expect(looks.colours[_face.path], _colours);
    },
  );

  test("matches the steps to the face's own colours", () async {
    await make();
    expect(service.steps.first.effects, [
      {
        'category': 'foundation',
        'palettes': [
          {'color': '#E8C4AE'},
        ],
      },
    ]);
    expect(service.steps[1].effects.single['palettes'], [
      {'color': '#3B2A22'},
    ]);
  });

  test('records the look, then forgets its job', () async {
    final done = (await make()).last as MakeupDone;
    expect(looks.recorded, [done.look]);
    expect(
      done.look,
      MakeupLook(
        outfitSignature: _signature,
        date: _outfit.date,
        occasion: Occasion.work,
        palette: OutfitPalette.coolNeutral,
        cheeks: CheekColour.rose,
        lips: LipColour.rosyNude,
        before: _before,
        steps: [
          for (final (index, step) in _recipe(_matchedKey).steps.indexed)
            LookStep(
              title: step.title,
              howTo: step.howTo,
              products: step.products,
              picture: _step(index + 1),
            ),
        ],
        matched: true,
      ),
    );
    expect(keptJob(), isNull);
    expect(service.discarded, ['analysis-1', 'step-1', 'step-2', 'step-3']);
    verify(saveSetup('uid-1')).called(1);
  });

  test('analyses a face photo only once', () async {
    looks.colours[_face.path] = _colours;
    expect((await make()).last, isA<MakeupDone>());
    expect(service.analyses, isEmpty);
    expect(service.steps, hasLength(3));
  });

  test('never makes a look twice', () async {
    final made = (await make()).last as MakeupDone;
    service.uploads.clear();
    expect(await make(), [made]);
    expect(service.uploads, isEmpty);
    expect(service.analyses, hasLength(1));
    expect(service.steps, hasLength(3));
  });

  test('uses neutral colours when the photo was not clear', () async {
    service.analysed = const FaceColours(
      skin: '#E8C4AE',
      eyebrow: '#3B2A22',
      lip: '#C98276',
      hair: '#42280E',
      clear: false,
    );
    final done = (await make()).last as MakeupDone;
    expect(done.look.matched, isFalse);
    expect(service.steps.first.effects.single['palettes'], [
      {'color': '#C69C82'},
    ]);
  });

  test("takes the weather from the outfit's cell when not given", () async {
    final updates = await make(
      null,
      MakeLookParams(accountId: 'uid-1', outfit: _outfit),
    );
    expect(updates.last, isA<MakeupDone>());
  });

  test('does nothing at all in a build without makeup', () async {
    service.available = false;
    expect(await make(), [
      const MakeupFailed(MakeupFailure(MakeupProblem.unavailable)),
    ]);
    verifyNever(saveSetup(any));
    expect(service.uploads, isEmpty);
    expect(keptJob(), isNull);
  });

  test('needs the face photo', () async {
    photos.face = null;
    expect(await make(), [
      const MakeupFailed(MakeupFailure(MakeupProblem.photo)),
    ]);
    expect(service.uploads, isEmpty);
  });

  test(
    'says the face cannot be used, and analyses it again next time',
    () async {
      service.analysisProblem = MakeupProblem.photo;
      expect(
        (await make()).last,
        const MakeupFailed(MakeupFailure(MakeupProblem.photo)),
      );
      expect(keptJob()!.analysisTask, isNull);
      expect(looks.colours, isEmpty);
    },
  );

  test(
    'stops when the service refuses a step, keeping the steps made',
    () async {
      service.refuseStep = 2;
      expect(
        (await make()).last,
        const MakeupFailed(MakeupFailure(MakeupProblem.failed)),
      );
      expect(keptJob()!.tasks, ['step-1']);
      expect(keptJob()!.pictures, ['step-1.jpg']);
    },
  );

  test(
    'tries a failed step again next time, keeping the steps before it',
    () async {
      service.failTask = 'step-2';
      expect(
        (await make()).last,
        const MakeupFailed(MakeupFailure(MakeupProblem.photo)),
      );
      expect(keptJob()!.tasks, ['step-1']);

      service.failTask = null;
      expect((await make()).last, isA<MakeupDone>());
      // Neither the analysis nor step 1 was made twice.
      expect(service.analyses, hasLength(1));
      expect(service.uploads.skip(3), [_step(1), _step(2)]);
    },
  );

  test('starts a step again when nobody knows whether it started', () async {
    service.lostStep = 2;
    expect((await make()).last, const MakeupFailed(NetworkFailure()));
    expect(keptJob()!.tasks, ['step-1']);

    service.lostStep = null;
    expect((await make()).last, isA<MakeupDone>());
    expect(service.steps, hasLength(4));
  });

  test('goes on where a cut-short look stopped', () async {
    looks
      ..colours[_face.path] = _colours
      ..kept.addAll([_before, _step(1)]);
    await jobs.save(
      MakeupJob(
        accountId: 'uid-1',
        outfitSignature: _signature,
        faceRevision: 1,
        updatedAt: clock.now(),
        before: 'before.png',
        recipeKey: _matchedKey,
        tasks: const ['old-1'],
        pictures: const ['step-1.jpg'],
      ),
    );
    final updates = await make();
    expect(updates.last, isA<MakeupDone>());
    expect(_made(updates[1] as MakeupProgress), [true, false, false]);
    expect(service.uploads, [_step(1), _step(2)]);
    expect(service.steps, hasLength(2));
  });

  test(
    'waits for an analysis already started, without starting another',
    () async {
      await jobs.save(
        MakeupJob(
          accountId: 'uid-1',
          outfitSignature: _signature,
          faceRevision: 1,
          updatedAt: clock.now(),
          analysisTask: 'analysis-0',
        ),
      );
      expect((await make()).last, isA<MakeupDone>());
      expect(service.analyses, isEmpty);
      expect(service.discarded.first, 'analysis-0');
    },
  );

  test(
    'starts again when a kept job is too old or for another face photo',
    () async {
      final old = MakeupJob(
        accountId: 'uid-1',
        outfitSignature: _signature,
        faceRevision: 1,
        updatedAt: DateTime.utc(2026, 10, 16, 8),
        analysisTask: 'analysis-0',
      );
      await jobs.save(old);
      await withClock(Clock.fixed(DateTime.utc(2026, 10, 16, 11)), () async {
        expect(await makeLook().underway(_params), isFalse);
        expect((await make()).last, isA<MakeupDone>());
      });
      expect(service.analyses, ['file-1']);

      looks.recorded.clear();
      looks.made = null;
      await jobs.save(
        MakeupJob(
          accountId: 'uid-1',
          outfitSignature: _signature,
          faceRevision: 7,
          updatedAt: clock.now(),
          analysisTask: 'analysis-0',
        ),
      );
      expect(await makeLook().underway(_params), isFalse);
    },
  );

  test('gives up waiting on a slow step but keeps it for next time', () async {
    looks.colours[_face.path] = _colours;
    service.runForever = true;
    final updates = await make(makeLook(taskTimeLimit: Duration.zero));
    expect(updates.last, const MakeupFailed(ServerFailure()));
    expect(keptJob()!.tasks, ['step-1']);
    expect(await makeLook().underway(_params), isTrue);
  });

  test('runs one making per look; a second ask follows it', () async {
    final maker = makeLook();
    final gate = Completer<void>();
    service.gate = gate.future;
    final first = maker(_params).toList();
    await pumpEventQueue();
    expect(await maker.underway(_params), isTrue);
    final second = maker(_params).toList();
    gate.complete();
    final (a, b) = (await first, await second);
    expect(a.last, isA<MakeupDone>());
    expect(b.first, isA<MakeupProgress>());
    expect(b.last, a.last);
    expect(service.analyses, hasLength(1));
    expect(service.steps, hasLength(3));
  });
}

/// Which steps have their picture.
List<bool> _made(MakeupProgress progress) => [
  for (final step in progress.steps) step.picture != null,
];

class _FakeLooks implements MakeupRepository {
  final recipes = {
    _neutralKey: _recipe(_neutralKey),
    _matchedKey: _recipe(_matchedKey),
  };
  final colours = <String, FaceColours>{};
  final kept = <String>{};
  final recorded = <MakeupLook>[];
  MakeupLook? made;

  @override
  Future<Either<Failure, MakeupRecipe?>> recipe(String key) async =>
      Right(recipes[key]);

  @override
  Future<Either<Failure, FaceColours?>> faceColours(
    String accountId,
    String facePhoto,
  ) async => Right(colours[facePhoto]);

  @override
  Future<Either<Failure, Unit>> saveFaceColours(
    String accountId,
    String facePhoto,
    FaceColours colours,
  ) async {
    this.colours[facePhoto] = colours;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, String?>> keptPicture(
    String accountId,
    String outfitSignature,
    String fileName,
  ) async {
    final path = '/phone/$outfitSignature/$fileName';
    return Right(kept.contains(path) ? path : null);
  }

  @override
  Future<Either<Failure, String>> keepPicture(
    String accountId,
    String outfitSignature,
    String name,
    List<int> picture,
  ) async {
    final path =
        '/phone/$outfitSignature/$name.${picture.first == 0x89 ? 'png' : 'jpg'}';
    kept.add(path);
    return Right(path);
  }

  @override
  Future<Either<Failure, Unit>> record(
    String accountId,
    MakeupLook look,
  ) async {
    recorded.add(look);
    made = look;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, MakeupLook?>> look(
    String accountId,
    String outfitSignature,
  ) async => Right(made?.outfitSignature == outfitSignature ? made : null);

  @override
  Future<Either<Failure, MakeupLook?>> latestLook(String accountId) async =>
      Right(made);

  @override
  Future<Either<Failure, Unit>> forgetPictures(String accountId) =>
      throw UnimplementedError();
}

/// YouCam on the phone: step task N's picture is https://r/step-N.
class _FakeService implements MakeupServiceRepository {
  @override
  bool available = true;

  final uploads = <String>[];
  final analyses = <String>[];
  final steps = <({String fileId, List<Map<String, Object?>> effects})>[];
  final discarded = <String>[];
  FaceColours analysed = _colours;
  MakeupProblem? analysisProblem;

  /// The step start, counted from 1, that the service refuses.
  int? refuseStep;

  /// The step start, counted from 1, whose answer is lost.
  int? lostStep;

  /// The step task that fails with a photo problem.
  String? failTask;
  bool runForever = false;
  Future<void>? gate;
  var _files = 0;
  var _tasks = 0;

  @override
  Future<Either<Failure, List<int>>> prepareFace(String path) async =>
      const Right([0x89, 0x50, 0x4E, 0x47]);

  @override
  Future<Either<Failure, String>> upload(String path) async {
    await gate;
    uploads.add(path);
    return Right('file-${++_files}');
  }

  @override
  Future<Either<Failure, String>> startAnalysis(String fileId) async {
    analyses.add(fileId);
    return const Right('analysis-1');
  }

  @override
  Future<Either<Failure, MakeupTask<FaceColours>>> checkAnalysis(
    String taskId,
  ) async {
    if (analysisProblem case final problem?) {
      return Right(MakeupTaskFailed(problem));
    }
    return Right(MakeupTaskDone(analysed));
  }

  @override
  Future<Either<Failure, String>> startStep(
    String fileId,
    List<Map<String, Object?>> effects,
  ) async {
    steps.add((fileId: fileId, effects: effects));
    if (steps.length == refuseStep) {
      return const Left(MakeupFailure(MakeupProblem.failed));
    }
    if (steps.length == lostStep) return const Left(NetworkFailure());
    return Right('step-${++_tasks}');
  }

  @override
  Future<Either<Failure, MakeupTask<String>>> checkStep(String taskId) async {
    if (runForever) return const Right(MakeupTaskRunning());
    if (taskId == failTask) {
      return const Right(MakeupTaskFailed(MakeupProblem.photo));
    }
    return Right(MakeupTaskDone('https://r/$taskId'));
  }

  @override
  Future<Either<Failure, List<int>>> download(String url) async =>
      const Right([0xFF, 0xD8, 0xFF]);

  @override
  Future<void> discard(String taskId) async => discarded.add(taskId);
}

class _FakePhotos implements PhotoRepository {
  UserPhoto? face = _face;

  @override
  Future<Either<Failure, UserPhoto?>> kept(PhotoRole role) async =>
      Right(role == PhotoRole.face ? face : null);

  @override
  Future<Either<Failure, String?>> choose() => throw UnimplementedError();

  @override
  Future<Either<Failure, UserPhoto>> keep(String path, PhotoRole role) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> forget(PhotoRole role) =>
      throw UnimplementedError();
}
