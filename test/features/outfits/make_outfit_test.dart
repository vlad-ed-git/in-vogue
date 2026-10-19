import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/colours/domain/entities/face_colours.dart';
import 'package:in_vogue/features/colours/domain/repositories/colour_profile_repository.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/try_on_job_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/day_model.dart';
import 'package:in_vogue/features/outfits/data/repositories/day_repository_impl.dart';
import 'package:in_vogue/features/outfits/data/repositories/try_on_job_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_pass.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/try_on_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/day_rules.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/domain/usecases/recommend_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as p;

import '../../helpers/catalog_outfits.dart';
import '../../helpers/day_bands.dart';
import '../../helpers/memory_store.dart';
import '../auth/sign_in_bloc_test.mocks.dart';

final _cool = bandsFor(WarmthBand.cool, rain: true);
final _today = DateTime.utc(2026, 10, 17);
final _tomorrow = DateTime.utc(2026, 10, 18);

MakeOutfitParams _params([DateTime? date]) => MakeOutfitParams(
  accountId: 'uid-1',
  date: date ?? _today,
  occasion: Occasion.work,
  bands: _cool,
);

const _body = UserPhoto(
  role: PhotoRole.body,
  path: '/support/photos/body-1.jpg',
  revision: 1,
);

final _coat = outfitOf('o1', const [
  ('everlane:jeans', GarmentCategory.lowerBody, 'jeans'),
  ('everlane:tee', GarmentCategory.upperBody, 'tee'),
  ('everlane:coat', GarmentCategory.outer, 'coat'),
]);

final _dress = outfitOf('o2', const [
  ('everlane:dress', GarmentCategory.fullBody, 'dress'),
]);

/// A one-piece outfit.
CatalogOutfit _top(String id) =>
    outfitOf(id, [('everlane:$id', GarmentCategory.upperBody, 'tee')]);

void main() {
  late DateTime time;
  late FakeFirebaseFirestore firestore;
  late Directory phone;
  late _FakePictures pictures;
  late DayRepositoryImpl days;
  late _FakeCatalog outfits;
  late _FakeTryOn tryOn;
  late MemoryStore store;
  late TryOnJobRepositoryImpl jobs;
  late _FakePhotos photos;
  late _Colours colours;
  late MockSaveSetupToAccount saveSetup;

  MakeOutfit makeOutfit({
    String device = 'phone-a',
    Duration passTimeLimit = const Duration(minutes: 4),
  }) => MakeOutfit(
    catalog: outfits,
    recommend: RecommendOutfit(outfits),
    colours: colours,
    days: days,
    tryOn: tryOn,
    jobs: jobs,
    photos: photos,
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

  Day dayOf(CatalogOutfit outfit, String device) => Day(
    date: _today,
    occasion: Occasion.work,
    outfitId: outfit.id,
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
      fingerprints: _fingerprints,
      logMessages: LogMessagesImpl(),
    );
    outfits = _FakeCatalog([_coat, _dress]);
    tryOn = _FakeTryOn();
    store = MemoryStore();
    jobs = TryOnJobRepositoryImpl(TryOnJobLocalDataSourceImpl(store));
    photos = _FakePhotos();
    colours = _Colours();
    saveSetup = MockSaveSetupToAccount();
    when(saveSetup(any)).thenAnswer((_) async => const Right(unit));
  });

  tearDown(() => phone.delete(recursive: true));

  group('a photo and outfit are tried on once', () {
    final later = DateTime.utc(2026, 10, 19);

    test('keeps the picture under the photo and outfit, on the account and '
        'the phone', () async {
      await make();
      final made = await firestore.collection('users/uid-1/tryOns').get();
      expect(made.docs.single.data(), {
        'photo': sha256.convert(utf8.encode(_body.path)).toString(),
        'outfitId': 'o1',
        'picturePath': 'users/uid-1/days/2026-10-17_work.jpg',
        'madeAt': isA<Timestamp>(),
      });
    });

    test('a later day with the same outfit takes the picture made before, '
        'at once and with no try-on', () async {
      outfits = _FakeCatalog([_coat]);
      await make();
      final updates = await make(params: _params(later));
      expect(updates, [isA<TryOnDone>()]);
      expect(tryOn.uploads, hasLength(1));
      expect(tryOn.starts, hasLength(3));
      expect(pictures.files.keys, ['users/uid-1/days/2026-10-17_work.jpg']);
      final day = await record(later);
      expect(day?['status'], 'ready');
      expect(day?['picturePath'], 'users/uid-1/days/2026-10-17_work.jpg');
      final done = updates.single as TryOnDone;
      expect(done.outfit.outfit, _coat);
      expect(done.outfit.date, later);
      expect(File(done.outfit.picture).existsSync(), isTrue);
    });

    test('another phone, or this one after a reinstall, finds it on the '
        'account', () async {
      outfits = _FakeCatalog([_coat]);
      await make();
      final empty = await Directory.systemTemp.createTemp('outfits');
      addTearDown(() => empty.delete(recursive: true));
      days = DayRepositoryImpl(
        remoteDataSource: DayRemoteDataSourceImpl(firestore),
        pictureRemoteDataSource: pictures,
        pictureLocalDataSource: OutfitPictureLocalDataSourceImpl(empty.path),
        fingerprints: _fingerprints,
        logMessages: LogMessagesImpl(),
      );
      final updates = await make(
        maker: makeOutfit(device: 'phone-b'),
        params: _params(later),
      );
      expect(updates, [isA<TryOnDone>()]);
      expect(tryOn.starts, hasLength(3));
      final done = updates.single as TryOnDone;
      expect(p.isWithin(empty.path, done.outfit.picture), isTrue);
    });

    test('a new photo is tried on anew', () async {
      outfits = _FakeCatalog([_coat]);
      await make();
      photos.body = const UserPhoto(
        role: PhotoRole.body,
        path: '/support/photos/body-2.jpg',
        revision: 2,
      );
      final updates = await make(params: _params(later));
      expect(updates.first, const TryOnProgress(piece: 1, pieces: 3));
      expect(updates.last, isA<TryOnDone>());
      expect(tryOn.starts, hasLength(6));
      expect(
        (await firestore.collection('users/uid-1/tryOns').get()).docs,
        hasLength(2),
      );
    });
  });

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
    expect(done.outfit.reason?.kind, ReasonKind.steady);
    expect((day?['reason'] as Map?)?['kind'], 'steady');
    expect((day?['cold'], day?['warm'], day?['rain']), ('cool', 'cool', true));
    expect(File(done.outfit.picture).existsSync(), isTrue);
    expect(keptJob(), isNull);
    expect(tryOn.discarded, ['task-1', 'task-2', 'task-3']);
    final suggestion =
        (await firestore.doc('users/uid-1/suggestions/${_coat.id}').get())
            .data();
    expect(suggestion?['times'], 1);
  });

  test(
    'chooses an outfit never suggested; repeats only once all were',
    () async {
      await firestore.doc('users/uid-1/suggestions/${_coat.id}').set({
        'lastAt': Timestamp.fromDate(time.subtract(const Duration(days: 3))),
      });
      await make();
      expect((await record())?['outfitId'], 'o2');

      await firestore.doc('users/uid-1/suggestions/${_dress.id}').set({
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

  test("a clear reading keeps the person's colours; an unclear one is "
      'ignored, as is none', () async {
    final winter = outfitOf(
      'o1',
      const [('everlane:navy', GarmentCategory.fullBody, 'jumpsuit')],
      seasons: const [ColourSeason.trueWinter],
    );
    final spring = outfitOf(
      'o2',
      const [('everlane:peach', GarmentCategory.fullBody, 'jumpsuit')],
      seasons: const [ColourSeason.lightSpring],
    );
    outfits = _FakeCatalog([winter, spring]);
    // Golden blonde hair on peachy fair skin: Light Spring.
    colours.read = const FaceColours(
      skin: '#F3D3B5',
      eyebrow: '#A07850',
      lip: '#B5726E',
      hair: '#C9A26B',
      clear: true,
    );
    await make();
    expect((await record())?['outfitId'], 'o2');
    expect(((await record())?['reason'] as Map?)?['season'], 'lightSpring');
    colours.read = const FaceColours(
      skin: '#F3D3B5',
      eyebrow: '#A07850',
      lip: '#B5726E',
      hair: '#C9A26B',
      clear: false,
    );
    await make(params: _params(_tomorrow));
    // The weather alone: both suit it, and o1 was never suggested.
    expect((await record(_tomorrow))?['outfitId'], 'o1');
    expect(((await record(_tomorrow))?['reason'] as Map?)?['season'], isNull);
  });

  test('never chooses an outfit with a piece whose photo was refused; says so '
      'when every outfit has one', () async {
    await firestore.doc('users/uid-1/suggestions/other').set({
      'refusedPiece': 'everlane:tee',
    });
    await make();
    expect((await record())?['outfitId'], 'o2');

    await firestore.doc('users/uid-1/suggestions/another').set({
      'refusedPiece': 'everlane:dress',
    });
    expect(await make(params: _params(_tomorrow)), [
      const TryOnFailed(TryOnFailure(TryOnProblem.reference)),
    ]);
    expect(await record(_tomorrow), isNull);
  });

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

  test("when YouCam refuses a piece's photo, remembers the piece and goes on "
      'with another outfit', () async {
    tryOn.referenceTasks = {'task-2'};
    final updates = await make();
    expect(updates, [
      const TryOnProgress(piece: 1, pieces: 3),
      const TryOnProgress(piece: 2, pieces: 3),
      const TryOnProgress(piece: 1, pieces: 1),
      isA<TryOnDone>(),
    ]);
    expect((updates.last as TryOnDone).outfit.outfit, _dress);
    final day = await record();
    expect(day?['status'], 'ready');
    expect(day?['outfitId'], 'o2');
    Future<Map<String, Object?>?> suggestion(CatalogOutfit outfit) async =>
        (await firestore.doc('users/uid-1/suggestions/${outfit.id}').get())
            .data();
    expect((await suggestion(_coat))?['refusedPiece'], 'everlane:tee');
    expect((await suggestion(_dress))?['times'], 1);
    expect(tryOn.discarded, unorderedEquals(['task-1', 'task-2', 'task-3']));
    expect(keptJob(), isNull);
  });

  test('gives up after three outfits refused in a row, keeping the refusal '
      'on the day for every phone', () async {
    outfits = _FakeCatalog([_coat, _dress, _top('o3'), _top('o4')]);
    tryOn.referenceTasks = {'task-1', 'task-2', 'task-3', 'task-4'};
    final updates = await make();
    expect(
      updates.last,
      const TryOnFailed(TryOnFailure(TryOnProblem.reference)),
    );
    expect(tryOn.starts, hasLength(3));
    final day = await record();
    expect(day?['status'], 'failed');
    expect(day?['problem'], 'reference');
    expect(day?['outfitId'], 'o3');
  });

  test('keeps the refusal on the day when no outfit is left to try', () async {
    tryOn.referenceTasks = {'task-1', 'task-2'};
    final updates = await make();
    expect(
      updates.last,
      const TryOnFailed(TryOnFailure(TryOnProblem.reference)),
    );
    final day = await record();
    expect(day?['status'], 'failed');
    expect(day?['problem'], 'reference');
  });

  test(
    "makes a day that failed on a piece's photo with another outfit",
    () async {
      await setDay(dayOf(_coat, 'phone-b').failedWith(TryOnProblem.reference));
      await firestore.doc('users/uid-1/suggestions/${_coat.id}').set({
        'lastAt': Timestamp.fromDate(time),
        'refusedPiece': 'everlane:tee',
      });
      expect((await make()).last, isA<TryOnDone>());
      final day = await record();
      expect(day?['status'], 'ready');
      expect(day?['outfitId'], 'o2');
      verifyNever(saveSetup(any));
    },
  );

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
    outfits = _FakeCatalog(const []);
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

/// Fingerprints from the photo's path, as these photos aren't on disk.
final _fingerprints = PhotoFingerprints(
  read: (path) async => utf8.encode(path),
);

class _FakeCatalog implements OutfitCatalogRepository {
  _FakeCatalog(this.catalog);
  final List<CatalogOutfit> catalog;

  @override
  Future<Either<Failure, List<CatalogOutfit>>> outfits() async =>
      Right(catalog);

  @override
  Future<Either<Failure, List<CatalogOutfit>>> sample() =>
      throw UnimplementedError();
}

/// The person's colours, never read unless given.
class _Colours implements ColourProfileRepository {
  FaceColours? read;

  @override
  Future<Either<Failure, FaceColours?>> latest(String accountId) async =>
      Right(read);

  @override
  Future<Either<Failure, FaceColours?>> colours(
    String accountId,
    String facePhoto,
  ) => throw UnimplementedError();

  @override
  Future<Either<Failure, Unit>> save(
    String accountId,
    String facePhoto,
    FaceColours colours,
  ) => throw UnimplementedError();
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

  /// Tasks refused for their reference photo.
  Set<String> referenceTasks = {};
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
    if (referenceTasks.contains(taskId)) {
      return const Right(TryOnErrored(TryOnProblem.reference));
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
