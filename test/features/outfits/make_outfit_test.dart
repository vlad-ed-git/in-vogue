import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/unit_budget_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/memory_store.dart';
import '../auth/sign_in_bloc_test.mocks.dart';

const _cool = WeatherClass(
  band: WarmthBand.cool,
  precipitation: Precipitation.wet,
  windy: false,
);
const _cell = 'cool|wet|calm|work';
final _day = DateTime.utc(2026, 10, 17);
final _params = MakeOutfitParams(
  accountId: 'uid-1',
  date: _day,
  occasion: Occasion.work,
  weatherClass: _cool,
);
const _body = UserPhoto(
  role: PhotoRole.body,
  path: '/support/photos/body-1.jpg',
  revision: 1,
);

const _coat = Outfit(
  id: 'o1',
  signature: 'coat+jeans+tee',
  pieces: ['everlane:jeans', 'everlane:tee', 'everlane:coat'],
  passes: [
    TryOnPass(
      category: GarmentCategory.lowerBody,
      piece: 'everlane:jeans',
      reference: 'https://cdn.example/jeans.jpg',
    ),
    TryOnPass(
      category: GarmentCategory.upperBody,
      piece: 'everlane:tee',
      reference: 'https://cdn.example/tee.jpg',
    ),
    TryOnPass(
      category: GarmentCategory.outer,
      piece: 'everlane:coat',
      reference: 'https://cdn.example/coat.jpg',
    ),
  ],
  reasons: {_cell: 'A coat over a tee with jeans for a cool, wet workday.'},
);

const _dress = Outfit(
  id: 'o2',
  signature: 'dress',
  pieces: ['everlane:dress'],
  passes: [
    TryOnPass(
      category: GarmentCategory.fullBody,
      piece: 'everlane:dress',
      reference: 'https://cdn.example/dress.jpg',
    ),
  ],
);

void main() {
  late _FakeOutfits outfits;
  late _FakeTryOn tryOn;
  late _FakeBudget budget;
  late MemoryStore store;
  late TryOnJobRepositoryImpl jobs;
  late _FakePhotos photos;
  late MockSaveSetupToAccount saveSetup;

  MakeOutfit makeOutfit({
    Duration passTimeLimit = const Duration(minutes: 4),
  }) => MakeOutfit(
    outfits: outfits,
    tryOn: tryOn,
    budget: budget,
    jobs: jobs,
    photos: photos,
    picks: _FakePicks(),
    saveSetupToAccount: saveSetup,
    checkEvery: Duration.zero,
    passTimeLimit: passTimeLimit,
  );

  Future<List<TryOnUpdate>> make([MakeOutfit? maker]) =>
      (maker ?? makeOutfit())(_params).toList();

  TryOnJob? keptJob() => TryOnJobLocalDataSourceImpl(store).jobs()[_params.key];

  setUp(() {
    outfits = _FakeOutfits([_coat, _dress]);
    tryOn = _FakeTryOn();
    budget = _FakeBudget();
    store = MemoryStore();
    jobs = TryOnJobRepositoryImpl(TryOnJobLocalDataSourceImpl(store));
    photos = _FakePhotos();
    saveSetup = MockSaveSetupToAccount();
    when(saveSetup(any)).thenAnswer((_) async => const Right(unit));
  });

  test(
    'tries the outfit on piece by piece, each on the last picture',
    () async {
      final updates = await make();
      expect(updates, [
        const TryOnProgress(piece: 1, pieces: 3),
        const TryOnProgress(piece: 2, pieces: 3),
        const TryOnProgress(piece: 3, pieces: 3),
        isA<TryOnDone>(),
      ]);
      expect(tryOn.uploads, ['/support/photos/body-1.jpg']);
      expect(tryOn.starts, [
        (pass: _coat.passes[0], fileId: 'file-1', pictureUrl: null),
        (pass: _coat.passes[1], fileId: null, pictureUrl: 'https://r/task-1'),
        (pass: _coat.passes[2], fileId: null, pictureUrl: 'https://r/task-2'),
      ]);
      expect(tryOn.downloads, ['https://r/task-3']);
      expect(budget.spent, 6);
    },
  );

  test('saves the setup on the account before choosing', () async {
    await make();
    verify(saveSetup('uid-1')).called(1);
  });

  test('records the outfit made, then forgets its job', () async {
    final done = (await make()).last as TryOnDone;
    expect(outfits.recorded, [
      (outfit: _coat, cell: _cell, date: _day, occasion: Occasion.work),
    ]);
    expect(done.outfit.reason, _coat.reasons[_cell]);
    expect(keptJob(), isNull);
    expect(tryOn.discarded, ['task-1', 'task-2', 'task-3']);
  });

  test('never makes an outfit shown before', () async {
    outfits.shown.add(_coat.signature);
    await make();
    expect(outfits.recorded.single.outfit, _dress);
    expect(budget.spent, 2);
  });

  test(
    'says so when every outfit has been shown, and spends nothing',
    () async {
      outfits.shown.addAll([_coat.signature, _dress.signature]);
      expect(await make(), [
        const TryOnFailed(TryOnFailure(TryOnProblem.everySeen)),
      ]);
      expect(tryOn.starts, isEmpty);
      expect(budget.spent, 0);
    },
  );

  test('stops when the budget would pass its limit', () async {
    budget.limit = 4;
    final updates = await make();
    expect(
      updates.last,
      const TryOnFailed(TryOnFailure(TryOnProblem.budgetSpent)),
    );
    expect(tryOn.starts, hasLength(2));
    expect(budget.spent, 4);
    expect(outfits.recorded, isEmpty);
  });

  test('makes no try-on when the setup cannot be saved', () async {
    when(saveSetup(any)).thenAnswer((_) async => const Left(NetworkFailure()));
    expect(await make(), [const TryOnFailed(NetworkFailure())]);
    expect(tryOn.uploads, isEmpty);
    expect(budget.spent, 0);
  });

  test('needs the body photo', () async {
    photos.body = null;
    expect(await make(), [const TryOnFailed(TryOnFailure(TryOnProblem.photo))]);
    expect(budget.spent, 0);
  });

  test('gives the units back when the service refuses a pass', () async {
    tryOn.refuseStart = 2;
    final updates = await make();
    expect(updates.last, const TryOnFailed(TryOnFailure(TryOnProblem.failed)));
    expect(budget.spent, 2);
    expect(keptJob()!.tasks, ['task-1']);
    expect(keptJob()!.reservedPass, isNull);
  });

  test(
    'gives the units back when a pass fails, and tries it again next time',
    () async {
      tryOn.failTask = 'task-2';
      final first = await make();
      expect(first.last, const TryOnFailed(TryOnFailure(TryOnProblem.photo)));
      expect(budget.spent, 2);
      expect(keptJob()!.tasks, ['task-1']);

      tryOn.failTask = null;
      final again = await make();
      expect(again.last, isA<TryOnDone>());
      // Pass 1 was not paid for twice.
      expect(budget.spent, 6);
      expect(tryOn.uploads, hasLength(1));
      expect(tryOn.starts.skip(2).map((start) => start.pictureUrl), [
        'https://r/task-1',
        'https://r/task-3',
      ]);
    },
  );

  test(
    'keeps the units when a pass may have started but nobody knows',
    () async {
      tryOn.lostStart = 2;
      final first = await make();
      expect(first.last, const TryOnFailed(NetworkFailure()));
      expect(budget.spent, 4);
      expect(keptJob()!.reservedPass, 1);

      tryOn.lostStart = null;
      expect((await make()).last, isA<TryOnDone>());
      // The reserved units paid for the pass on the next attempt.
      expect(budget.spent, 6);
    },
  );

  test('goes on where a cut-short try-on stopped', () async {
    await jobs.save(
      TryOnJob(
        accountId: 'uid-1',
        date: _day,
        occasion: Occasion.work,
        cell: _cell,
        outfitId: 'o1',
        photoRevision: 1,
        updatedAt: clock.now(),
        tasks: const ['old-1', 'old-2'],
      ),
    );
    final updates = await make();
    expect(updates.last, isA<TryOnDone>());
    expect(tryOn.uploads, isEmpty);
    expect(tryOn.starts.single.pictureUrl, 'https://r/old-2');
    expect(budget.spent, 2);
    verifyNever(saveSetup(any));
  });

  test(
    'starts again when a kept job is too old to download or for another photo',
    () async {
      final stale = TryOnJob(
        accountId: 'uid-1',
        date: _day,
        occasion: Occasion.work,
        cell: _cell,
        outfitId: 'o1',
        photoRevision: 1,
        updatedAt: DateTime.utc(2026, 10, 16, 8),
        tasks: const ['old-1'],
      );
      await jobs.save(stale);
      await withClock(Clock.fixed(DateTime.utc(2026, 10, 16, 11)), () async {
        expect((await make()).last, isA<TryOnDone>());
      });
      expect(tryOn.starts, hasLength(3));
      expect(budget.spent, 6);
    },
  );

  test('gives up waiting on a slow pass but keeps it for next time', () async {
    tryOn.runForever = true;
    final updates = await make(makeOutfit(passTimeLimit: Duration.zero));
    expect(updates.last, const TryOnFailed(ServerFailure()));
    expect(budget.spent, 2);
    expect(keptJob()!.tasks, ['task-1']);
  });

  test(
    'runs one making per day and occasion; a second ask follows it',
    () async {
      final maker = makeOutfit();
      final gate = Completer<void>();
      tryOn.gate = gate.future;
      final first = maker(_params).toList();
      await pumpEventQueue();
      final second = maker(_params).toList();
      gate.complete();
      final (a, b) = (await first, await second);
      expect(a.last, isA<TryOnDone>());
      expect(b.first, const TryOnProgress(piece: 1, pieces: 3));
      expect(b.last, a.last);
      expect(tryOn.uploads, hasLength(1));
      expect(budget.spent, 6);
    },
  );
}

class _FakeOutfits implements OutfitRepository {
  _FakeOutfits(this.ranked);

  final List<Outfit> ranked;
  final shown = <String>{};
  final recorded =
      <({Outfit outfit, String cell, DateTime date, Occasion occasion})>[];

  @override
  Future<Either<Failure, List<Outfit>>> outfitsFor(String cell) async =>
      Right(cell == _cell ? ranked : const []);

  @override
  Future<Either<Failure, Outfit?>> outfit(String id) async =>
      Right(ranked.where((outfit) => outfit.id == id).firstOrNull);

  @override
  Future<Either<Failure, Set<String>>> shownSignatures(
    String accountId,
  ) async => Right({...shown});

  @override
  Future<Either<Failure, DayOutfit?>> dayOutfit(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  }) async => const Right(null);

  @override
  Future<Either<Failure, DayOutfit>> record(
    String accountId, {
    required Outfit outfit,
    required String cell,
    required DateTime date,
    required Occasion occasion,
    required List<int> picture,
  }) async {
    recorded.add((outfit: outfit, cell: cell, date: date, occasion: occasion));
    shown.add(outfit.signature);
    return Right(
      DayOutfit(
        outfit: outfit,
        date: date,
        occasion: occasion,
        cell: cell,
        picture: '/support/outfits/uid-1/${outfit.signature}.jpg',
      ),
    );
  }
}

/// YouCam on the phone: task N's picture is https://r/task-N.
class _FakeTryOn implements TryOnRepository {
  final uploads = <String>[];
  final starts = <({TryOnPass pass, String? fileId, String? pictureUrl})>[];
  final downloads = <String>[];
  final discarded = <String>[];

  /// The start, counted from 1, that the service refuses.
  int? refuseStart;

  /// The start, counted from 1, whose answer is lost.
  int? lostStart;

  /// The task that fails with a photo problem.
  String? failTask;
  bool runForever = false;
  Future<void>? gate;
  var _tasks = 0;

  @override
  Future<Either<Failure, String>> upload(String path) async {
    await gate;
    uploads.add(path);
    return const Right('file-1');
  }

  @override
  Future<Either<Failure, String>> start(
    TryOnPass pass, {
    String? fileId,
    String? pictureUrl,
  }) async {
    starts.add((pass: pass, fileId: fileId, pictureUrl: pictureUrl));
    if (starts.length == refuseStart) {
      return const Left(TryOnFailure(TryOnProblem.failed));
    }
    if (starts.length == lostStart) return const Left(NetworkFailure());
    return Right('task-${++_tasks}');
  }

  @override
  Future<Either<Failure, TryOnTask>> check(String taskId) async {
    if (runForever) return const Right(TryOnRunning());
    if (taskId == failTask) {
      return const Right(TryOnErrored(TryOnProblem.photo));
    }
    return Right(TryOnSucceeded('https://r/$taskId'));
  }

  @override
  Future<Either<Failure, List<int>>> download(String url) async {
    downloads.add(url);
    return const Right([0xFF, 0xD8, 0xFF]);
  }

  @override
  Future<void> discard(String taskId) async => discarded.add(taskId);
}

class _FakeBudget implements UnitBudgetRepository {
  int limit = 15;
  int spent = 0;

  @override
  Future<Either<Failure, Unit>> reserve(int units) async {
    if (spent + units > limit) {
      return const Left(TryOnFailure(TryOnProblem.budgetSpent));
    }
    spent += units;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, Unit>> release(int units) async {
    spent -= units;
    return const Right(unit);
  }
}

class _FakePhotos implements PhotoRepository {
  UserPhoto? body = _body;

  @override
  Future<Either<Failure, UserPhoto?>> kept(PhotoRole role) async =>
      Right(role == PhotoRole.body ? body : null);

  @override
  Future<Either<Failure, String?>> choose() => throw UnimplementedError();

  @override
  Future<Either<Failure, UserPhoto>> keep(String path, PhotoRole role) =>
      throw UnimplementedError();
}

class _FakePicks implements PicksRepository {
  @override
  Future<Either<Failure, Set<String>>> picks() async => const Right({});

  @override
  Future<Either<Failure, Set<String>>> setPick(
    String colourwayId, {
    required bool loved,
  }) => throw UnimplementedError();
}
