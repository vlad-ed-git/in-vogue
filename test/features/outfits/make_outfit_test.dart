import 'dart:async';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/day_model.dart';
import 'package:in_vogue/features/outfits/data/repositories/day_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/day_rules.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
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
final _today = DateTime.utc(2026, 10, 17);
final _tomorrow = DateTime.utc(2026, 10, 18);

MakeOutfitParams _params([DateTime? date]) => MakeOutfitParams(
  accountId: 'uid-1',
  date: date ?? _today,
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
  late DateTime time;
  late FakeFirebaseFirestore firestore;
  late Directory phone;
  late _FakePictures pictures;
  late DayRepositoryImpl days;
  late _FakeOutfits outfits;
  late _FakeTryOn tryOn;
  late MemoryStore store;
  late TryOnJobRepositoryImpl jobs;
  late _FakePhotos photos;
  late MockSaveSetupToAccount saveSetup;

  MakeOutfit makeOutfit({
    String device = 'phone-a',
    Duration passTimeLimit = const Duration(minutes: 4),
  }) => MakeOutfit(
    outfits: outfits,
    days: days,
    tryOn: tryOn,
    jobs: jobs,
    photos: photos,
    picks: _FakePicks(),
    saveSetupToAccount: saveSetup,
    installId: InstallId(device),
    checkEvery: Duration.zero,
    passTimeLimit: passTimeLimit,
  );

  // The fake's transactions write without waiting: let the writes land.
  Future<List<TryOnUpdate>> make({
    MakeOutfit? maker,
    MakeOutfitParams? params,
  }) => withClock(Clock(() => time), () async {
    final updates = await (maker ?? makeOutfit())(params ?? _params()).toList();
    await pumpEventQueue();
    return updates;
  });

  Future<Map<String, Object?>?> record([DateTime? date]) async =>
      (await firestore
              .doc(
                'users/uid-1/days/${Day.keyFor(date ?? _today, Occasion.work)}',
              )
              .get())
          .data();

  Future<void> setDay(Day day) => firestore
      .doc('users/uid-1/days/${day.key}')
      .set({...DayModel.toJson(day), 'updatedAt': Timestamp.fromDate(time)});

  Day dayOf(Outfit outfit, String device) => Day(
    date: _today,
    occasion: Occasion.work,
    cell: _cell,
    outfitId: outfit.id,
    signature: outfit.signature,
    status: DayStatus.making,
    device: device,
  );

  TryOnJob? keptJob() =>
      TryOnJobLocalDataSourceImpl(store).jobs()[_params().key];

  setUp(() async {
    time = DateTime.utc(2026, 10, 17, 8);
    firestore = FakeFirebaseFirestore(clock: Clock(() => time));
    phone = await Directory.systemTemp.createTemp('outfits');
    pictures = _FakePictures();
    days = DayRepositoryImpl(
      remoteDataSource: DayRemoteDataSourceImpl(firestore),
      pictureRemoteDataSource: pictures,
      pictureLocalDataSource: OutfitPictureLocalDataSourceImpl(phone.path),
      logMessages: LogMessagesImpl(),
    );
    outfits = _FakeOutfits([_coat, _dress]);
    tryOn = _FakeTryOn();
    store = MemoryStore();
    jobs = TryOnJobRepositoryImpl(TryOnJobLocalDataSourceImpl(store));
    photos = _FakePhotos();
    saveSetup = MockSaveSetupToAccount();
    when(saveSetup(any)).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() => phone.delete(recursive: true));

  test('claims the day, then tries the outfit on piece by piece, each on the '
      'last picture', () async {
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
    verify(saveSetup('uid-1')).called(1);
  });

  test('keeps the made day on the account and the phone', () async {
    final done = (await make()).last as TryOnDone;
    final day = await record();
    expect(day?['status'], 'ready');
    expect(day?['device'], 'phone-a');
    expect(day?['picturePath'], 'users/uid-1/days/2026-10-17_work.jpg');
    expect(pictures.files.keys, ['users/uid-1/days/2026-10-17_work.jpg']);
    expect(done.outfit.outfit, _coat);
    expect(done.outfit.reason, _coat.reasons[_cell]);
    expect(File(done.outfit.picture).existsSync(), isTrue);
    expect(keptJob(), isNull);
    expect(tryOn.discarded, ['task-1', 'task-2', 'task-3']);
    final suggestion =
        (await firestore
                .doc('users/uid-1/suggestions/${_coat.signature}')
                .get())
            .data();
    expect(suggestion?['times'], 1);
  });

  test(
    'chooses an outfit never suggested; repeats only once all were',
    () async {
      await firestore.doc('users/uid-1/suggestions/${_coat.signature}').set({
        'lastAt': Timestamp.fromDate(time.subtract(const Duration(days: 3))),
      });
      await make();
      expect((await record())?['outfitId'], 'o2');

      await firestore.doc('users/uid-1/suggestions/${_dress.signature}').set({
        'lastAt': Timestamp.fromDate(time.subtract(const Duration(days: 1))),
      });
      await make(params: _params(_tomorrow));
      expect((await record(_tomorrow))?['outfitId'], 'o1');
    },
  );

  test(
    'never gives today and tomorrow the same outfit, even at once',
    () async {
      final maker = makeOutfit();
      final both = await withClock(
        Clock(() => time),
        () => Future.wait([
          maker(_params()).toList(),
          maker(_params(_tomorrow)).toList(),
        ]),
      );
      await pumpEventQueue();
      expect(
        both.map((updates) => updates.last),
        everyElement(isA<TryOnDone>()),
      );
      expect(
        {(await record())?['outfitId'], (await record(_tomorrow))?['outfitId']},
        {'o1', 'o2'},
      );
    },
  );

  test('shows a day another phone made, without trying anything on', () async {
    await setDay(
      dayOf(_dress, 'phone-b').readyAt('users/uid-1/days/2026-10-17_work.jpg'),
    );
    pictures.files['users/uid-1/days/2026-10-17_work.jpg'] = const [1, 2];
    final updates = await make();
    final done = updates.single as TryOnDone;
    expect(done.outfit.outfit, _dress);
    expect(File(done.outfit.picture).readAsBytesSync(), [1, 2]);
    expect(tryOn.uploads, isEmpty);
    verifyNever(saveSetup(any));
  });

  test('leaves a day another phone is making', () async {
    await setDay(dayOf(_dress, 'phone-b').progressing(1, 1));
    final updates = await make();
    expect(updates.single, isA<TryOnElsewhere>());
    expect((updates.single as TryOnElsewhere).day.device, 'phone-b');
    expect(tryOn.uploads, isEmpty);
  });

  test("takes over a making that stopped, with the day's outfit", () async {
    await setDay(dayOf(_dress, 'phone-b'));
    time = time.add(DayRules.lease);
    final updates = await make();
    expect(updates.last, isA<TryOnDone>());
    expect(tryOn.starts.single.pass, _dress.passes.single);
    expect((await record())?['device'], 'phone-a');
  });

  test('tries a failed day again with its outfit', () async {
    await setDay(dayOf(_dress, 'phone-b').failedWith(TryOnProblem.failed));
    expect((await make()).last, isA<TryOnDone>());
    expect((await record())?['status'], 'ready');
    expect((await record())?['outfitId'], 'o2');
  });

  test('stops when another phone takes the day over midway', () async {
    tryOn.onStart = (made) async {
      if (made == 2) {
        await firestore.doc('users/uid-1/days/2026-10-17_work').update({
          'device': 'phone-b',
        });
      }
    };
    final updates = await make();
    expect(updates.last, isA<TryOnElsewhere>());
    expect(tryOn.starts, hasLength(2));
    expect((await record())?['status'], 'making');
  });

  test("keeps YouCam's refusal on the day for every phone", () async {
    tryOn.refuseStart = 2;
    final updates = await make();
    expect(updates.last, const TryOnFailed(TryOnFailure(TryOnProblem.failed)));
    final day = await record();
    expect(day?['status'], 'failed');
    expect(day?['problem'], 'failed');
    expect(keptJob()!.tasks, ['task-1']);
  });

  test(
    'tries a failed pass again next time, keeping the passes before it',
    () async {
      tryOn.failTask = 'task-2';
      final first = await make();
      expect(first.last, const TryOnFailed(TryOnFailure(TryOnProblem.photo)));
      expect(keptJob()!.tasks, ['task-1']);

      tryOn.failTask = null;
      final again = await make();
      expect(again.last, isA<TryOnDone>());
      // Pass 1 was not made twice.
      expect(tryOn.starts, hasLength(4));
      expect(tryOn.uploads, hasLength(1));
      expect(tryOn.starts.skip(2).map((start) => start.pictureUrl), [
        'https://r/task-1',
        'https://r/task-3',
      ]);
    },
  );

  test('keeps the day with this phone when the network fails, and goes on '
      'next time', () async {
    tryOn.lostStart = 2;
    final first = await make();
    expect(first.last, const TryOnFailed(NetworkFailure()));
    expect((await record())?['status'], 'making');
    expect(keptJob()!.tasks, ['task-1']);

    tryOn.lostStart = null;
    expect((await make()).last, isA<TryOnDone>());
    expect(tryOn.starts.skip(2).map((start) => start.pass), [
      _coat.passes[1],
      _coat.passes[2],
    ]);
  });

  test('goes on where a cut-short try-on stopped', () async {
    await setDay(dayOf(_coat, 'phone-a').progressing(3, 3));
    await jobs.save(
      TryOnJob(
        accountId: 'uid-1',
        date: _today,
        occasion: Occasion.work,
        cell: _cell,
        outfitId: 'o1',
        photoRevision: 1,
        updatedAt: time,
        tasks: const ['old-1', 'old-2'],
      ),
    );
    final updates = await make();
    expect(updates.last, isA<TryOnDone>());
    expect(tryOn.uploads, isEmpty);
    expect(tryOn.starts.single.pictureUrl, 'https://r/old-2');
    verifyNever(saveSetup(any));
  });

  test(
    'starts again when a kept job is too old or for another photo',
    () async {
      await jobs.save(
        TryOnJob(
          accountId: 'uid-1',
          date: _today,
          occasion: Occasion.work,
          cell: _cell,
          outfitId: 'o1',
          photoRevision: 1,
          updatedAt: time.subtract(const Duration(hours: 3)),
          tasks: const ['old-1'],
        ),
      );
      expect((await make()).last, isA<TryOnDone>());
      expect(tryOn.starts, hasLength(3));
    },
  );

  test('makes no try-on when the setup cannot be saved', () async {
    when(saveSetup(any)).thenAnswer((_) async => const Left(NetworkFailure()));
    expect(await make(), [const TryOnFailed(NetworkFailure())]);
    expect(tryOn.uploads, isEmpty);
    expect(await record(), isNull);
  });

  test('does nothing at all in a build without try-ons', () async {
    tryOn.available = false;
    expect(await make(), [
      const TryOnFailed(TryOnFailure(TryOnProblem.unavailable)),
    ]);
    verifyNever(saveSetup(any));
    expect(await record(), isNull);
  });

  test('tries nothing on when no outfit suits the weather', () async {
    outfits = _FakeOutfits(const []);
    expect(await make(), [
      const TryOnFailed(TryOnFailure(TryOnProblem.unavailable)),
    ]);
    expect(tryOn.uploads, isEmpty);
    expect(await record(), isNull);
  });

  test('needs the body photo', () async {
    photos.body = null;
    expect(await make(), [const TryOnFailed(TryOnFailure(TryOnProblem.photo))]);
    expect(await record(), isNull);
  });

  test('gives up waiting on a slow pass but keeps it for next time', () async {
    tryOn.runForever = true;
    final updates = await make(maker: makeOutfit(passTimeLimit: Duration.zero));
    expect(updates.last, const TryOnFailed(ServerFailure()));
    expect(keptJob()!.tasks, ['task-1']);
    expect((await record())?['status'], 'making');
  });

  test(
    'runs one making per day and occasion; a second ask follows it',
    () async {
      final maker = makeOutfit();
      final gate = Completer<void>();
      tryOn.gate = gate.future;
      final (a, b) = await withClock(Clock(() => time), () async {
        final first = maker(_params()).toList();
        await pumpEventQueue();
        expect(maker.isMaking(_params()), isTrue);
        final second = maker(_params()).toList();
        gate.complete();
        return (await first, await second);
      });
      expect(a.last, isA<TryOnDone>());
      expect(b.first, const TryOnProgress(piece: 1, pieces: 3));
      expect(b.last, a.last);
      expect(tryOn.uploads, hasLength(1));
      expect(maker.isMaking(_params()), isFalse);
    },
  );
}

class _FakeOutfits implements OutfitRepository {
  _FakeOutfits(this.ranked);
  final List<Outfit> ranked;

  @override
  Future<Either<Failure, List<Outfit>>> outfitsFor(String cell) async =>
      Right(cell == _cell ? ranked : const []);

  @override
  Future<Either<Failure, Outfit?>> outfit(String id) async =>
      Right(ranked.where((outfit) => outfit.id == id).firstOrNull);
}

class _FakePictures implements OutfitPictureRemoteDataSource {
  final files = <String, List<int>>{};

  @override
  Future<void> upload(
    String path,
    List<int> picture, {
    required String contentType,
  }) async => files[path] = picture;

  @override
  Future<List<int>> download(String path) async => files[path]!;
}

/// YouCam on the phone: task N's picture is https://r/task-N.
class _FakeTryOn implements TryOnRepository {
  @override
  bool available = true;

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

  /// Runs at each start, with how many there have been.
  Future<void> Function(int made)? onStart;
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
    await onStart?.call(starts.length);
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

class _FakePhotos implements PhotoRepository {
  UserPhoto? body = _body;

  @override
  Future<Either<Failure, UserPhoto?>> kept(PhotoRole role) async =>
      Right(role == PhotoRole.body ? body : null);

  @override
  Future<Either<Failure, ChosenPhoto?>> choose(PhotoRole role) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, UserPhoto>> keep(String path, PhotoRole role) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> forget(PhotoRole role) =>
      throw UnimplementedError();
}

class _FakePicks implements PicksRepository {
  @override
  Future<Either<Failure, Set<String>>> picks() async => const Right({});

  @override
  Future<Either<Failure, Unit>> clear() => throw UnimplementedError();

  @override
  Future<Either<Failure, Set<String>>> setPick(
    String colourwayId, {
    required bool loved,
  }) => throw UnimplementedError();

  @override
  Future<Either<Failure, Set<String>>> synced(String accountId) =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> markSynced(
    String accountId,
    Set<String> picks,
  ) => throw UnimplementedError();
}
