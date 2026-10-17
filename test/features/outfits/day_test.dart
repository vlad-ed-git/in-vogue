import 'dart:io';

import 'package:clock/clock.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/data/data_sources/day_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/day_model.dart';
import 'package:in_vogue/features/outfits/data/repositories/day_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/services/day_rules.dart';

final _today = DateTime.utc(2026, 10, 17);
final _tomorrow = DateTime.utc(2026, 10, 18);
const _png = [0x89, 0x50, 0x4E, 0x47, 1];

Day _outfit(String id, {DateTime? date, String device = ''}) => Day(
  date: date ?? _tomorrow,
  occasion: Occasion.work,
  cell: 'cool|wet|calm|work',
  outfitId: id,
  signature: 'sig-$id',
  status: DayStatus.making,
  device: device,
);

void main() {
  group('DayRules', () {
    final now = DateTime.utc(2026, 10, 17, 8);
    Day making(String device, {Duration ago = Duration.zero}) => Day(
      date: _tomorrow,
      occasion: Occasion.work,
      cell: 'cool|wet|calm|work',
      outfitId: 'o1',
      signature: 'sig-o1',
      status: DayStatus.making,
      device: device,
      piece: 2,
      pieces: 3,
      updatedAt: now.subtract(ago),
    );

    test('gives a new day the proposed outfit, made here', () {
      final claim = DayRules.claim(
        current: null,
        proposal: _outfit('o2'),
        device: 'phone-a',
        now: now,
      );
      expect(claim.write?.device, 'phone-a');
      expect(claim.write?.outfitId, 'o2');
      expect(claim.claim, DayClaimed(claim.write!));
    });

    test('asks to choose again when there is neither day nor proposal', () {
      expect(
        DayRules.claim(
          current: null,
          proposal: null,
          device: 'phone-a',
          now: now,
        ).claim,
        const DayConflict(),
      );
    });

    test('goes on with its own making, without writing', () {
      final claim = DayRules.claim(
        current: making('phone-a'),
        proposal: null,
        device: 'phone-a',
        now: now,
      );
      expect(claim.write, isNull);
      expect(claim.claim, DayClaimed(making('phone-a')));
    });

    test("leaves another phone's making alone until it goes stale", () {
      final fresh = DayRules.claim(
        current: making('phone-b', ago: const Duration(minutes: 9)),
        proposal: _outfit('o2'),
        device: 'phone-a',
        now: now,
      );
      expect(fresh.write, isNull);
      expect(fresh.claim, isA<DayKept>());

      final stale = DayRules.claim(
        current: making('phone-b', ago: DayRules.lease),
        proposal: _outfit('o2'),
        device: 'phone-a',
        now: now,
      );
      expect(stale.write?.device, 'phone-a');
      expect(stale.write?.outfitId, 'o1');
      expect(stale.write?.piece, 0);
      expect(stale.claim, isA<DayClaimed>());
    });

    test('tries a failed day again with its outfit; keeps a made one', () {
      final failed = making('phone-b').failedWith(TryOnProblem.photo);
      final again = DayRules.claim(
        current: failed,
        proposal: _outfit('o2'),
        device: 'phone-a',
        now: now,
      );
      expect(again.write?.status, DayStatus.making);
      expect(again.write?.problem, isNull);
      expect(again.write?.outfitId, 'o1');

      final made = making('phone-b').readyAt('users/uid/days/x.jpg');
      final kept = DayRules.claim(
        current: made,
        proposal: null,
        device: 'phone-a',
        now: now,
      );
      expect(kept.write, isNull);
      expect(kept.claim, DayKept(made));
    });

    test('counts a making stale only once the server has its time', () {
      expect(
        DayRules.stale(making('phone-b', ago: const Duration(hours: 1)), now),
        isTrue,
      );
      expect(DayRules.stale(_outfit('o1', device: 'phone-b'), now), isFalse);
    });
  });

  test('DayModel keeps a day as its record, and reads it back', () {
    final day = _outfit(
      'o1',
      device: 'phone-a',
    ).progressing(2, 3).failedWith(TryOnProblem.photo);
    final read = DayModel.fromJson(
      DayModel.toJson(day),
      updatedAt: DateTime.utc(2026, 10, 17, 8),
    );
    expect(read, isNot(day));
    expect(DayModel.toJson(read!), DayModel.toJson(day));
    expect(read.updatedAt, DateTime.utc(2026, 10, 17, 8));
    expect(DayModel.fromJson(const {'forDate': '2026-10-18'}), isNull);
  });

  group('DayRepositoryImpl', () {
    late DateTime time;
    late FakeFirebaseFirestore firestore;
    late _FakePictures pictures;
    late Directory phone;
    late DayRepositoryImpl days;

    setUp(() async {
      time = DateTime.utc(2026, 10, 17, 8);
      firestore = FakeFirebaseFirestore(clock: Clock(() => time));
      pictures = _FakePictures();
      phone = await Directory.systemTemp.createTemp('days');
      days = DayRepositoryImpl(
        remoteDataSource: DayRemoteDataSourceImpl(firestore),
        pictureRemoteDataSource: pictures,
        pictureLocalDataSource: OutfitPictureLocalDataSourceImpl(phone.path),
        logMessages: LogMessagesImpl(),
      );
    });

    tearDown(() => phone.delete(recursive: true));

    // The fake's transactions write without waiting: let the writes land
    // before the clock moves on.
    Future<T> settled<T>(Future<T> call) async {
      final result = await call;
      await pumpEventQueue();
      return result;
    }

    Future<DayClaim> claim(
      String device, {
      Day? proposal,
      Map<String, DateTime?> suggested = const {},
      DateTime? date,
    }) => settled(
      withClock(
        Clock(() => time),
        () async => (await days.claim(
          'uid-1',
          date: date ?? _tomorrow,
          occasion: Occasion.work,
          proposal: proposal,
          suggested: suggested,
          device: device,
        )).getOrElse(() => throw StateError('claim')),
      ),
    );

    Future<Map<String, Object?>?> record(String path) async =>
        (await firestore.doc('users/uid-1/$path').get()).data();

    test('claims a new day and records its outfit as suggested', () async {
      final claimed = await claim('phone-a', proposal: _outfit('o1'));
      expect(claimed, isA<DayClaimed>());
      final day = await record('days/2026-10-18_work');
      expect(day?['status'], 'making');
      expect(day?['device'], 'phone-a');
      expect(day?['updatedAt'], isA<Timestamp>());
      final suggestion = await record('suggestions/sig-o1');
      expect(suggestion?['times'], 1);
      expect(suggestion?['lastForDate'], '2026-10-18');
      expect(suggestion?['firstAt'], isA<Timestamp>());
      expect(
        (await days.suggested('uid-1', [
          'sig-o1',
          'sig-o2',
        ])).getOrElse(() => const {}),
        {'sig-o1': time},
      );
    });

    test("keeps another phone's making until it goes stale, then takes "
        'it over with the same outfit', () async {
      await claim('phone-a', proposal: _outfit('o1'));
      time = time.add(const Duration(minutes: 9));
      final kept = await claim('phone-b', proposal: _outfit('o2'));
      expect(kept, isA<DayKept>());
      expect((kept as DayKept).day.device, 'phone-a');

      time = time.add(const Duration(minutes: 1));
      final taken = await claim('phone-b', proposal: _outfit('o2'));
      expect(taken, isA<DayClaimed>());
      expect((taken as DayClaimed).day.device, 'phone-b');
      expect(taken.day.outfitId, 'o1');
      expect((await record('days/2026-10-18_work'))?['device'], 'phone-b');
      expect(await record('suggestions/sig-o2'), isNull);
    });

    test('tries a failed day again; keeps a made one', () async {
      final claimed =
          await claim('phone-a', proposal: _outfit('o1')) as DayClaimed;
      await settled(
        days.fail('uid-1', claimed.day, TryOnProblem.photo, device: 'phone-a'),
      );
      expect((await record('days/2026-10-18_work'))?['problem'], 'photo');

      final again = await claim('phone-b') as DayClaimed;
      expect(again.day.status, DayStatus.making);
      expect(again.day.problem, isNull);
      expect(again.day.outfitId, 'o1');

      await settled(days.finish('uid-1', again.day, _png, device: 'phone-b'));
      final kept = await claim('phone-a', proposal: _outfit('o2'));
      expect(kept, isA<DayKept>());
      expect((kept as DayKept).day.status, DayStatus.ready);
    });

    test('asks to choose again when the outfit was suggested meanwhile, '
        'and writes nothing', () async {
      final seen = (await days.suggested('uid-1', [
        'sig-o1',
      ])).getOrElse(() => const {});
      expect(seen, isEmpty);
      await claim(
        'phone-b',
        proposal: _outfit('o1', date: _today),
        date: _today,
      );

      expect(
        await claim('phone-a', proposal: _outfit('o1'), suggested: seen),
        const DayConflict(),
      );
      expect(await record('days/2026-10-18_work'), isNull);

      final later = (await days.suggested('uid-1', [
        'sig-o1',
      ])).getOrElse(() => const {});
      time = time.add(const Duration(days: 1));
      await claim(
        'phone-b',
        proposal: _outfit('o1', date: DateTime.utc(2026, 10, 19)),
        suggested: later,
        date: DateTime.utc(2026, 10, 19),
      );
      expect(
        await claim('phone-a', proposal: _outfit('o1'), suggested: later),
        const DayConflict(),
      );
      expect((await record('suggestions/sig-o1'))?['times'], 2);
    });

    test('finds suggestions thirty at a time', () async {
      for (var index = 0; index < 35; index++) {
        await firestore.doc('users/uid-1/suggestions/sig-$index').set({
          'lastAt': Timestamp.fromDate(time.add(Duration(minutes: index))),
        });
      }
      final found = (await days.suggested('uid-1', [
        for (var index = 0; index < 40; index++) 'sig-$index',
      ])).getOrElse(() => const {});
      expect(found, hasLength(35));
      expect(found['sig-34'], time.add(const Duration(minutes: 34)));
      expect(found.containsKey('sig-39'), isFalse);
    });

    test("remembers a refused piece on its outfit's suggestion, and lists "
        "the account's refused pieces", () async {
      await claim('phone-a', proposal: _outfit('o1'));
      await settled(days.refuse('uid-1', 'sig-o1', 'everlane:tee'));
      final suggestion = await record('suggestions/sig-o1');
      expect(suggestion?['refusedPiece'], 'everlane:tee');
      expect(suggestion?['times'], 1, reason: 'the rest stays');
      await settled(days.refuse('uid-1', 'sig-o9', 'everlane:coat'));
      await firestore.doc('users/uid-1/suggestions/sig-o2').set({'times': 1});
      await firestore.doc('users/uid-2/suggestions/sig-o3').set({
        'refusedPiece': 'everlane:dress',
      });
      expect((await days.refusedPieces('uid-1')).getOrElse(() => const {}), {
        'everlane:tee',
        'everlane:coat',
      });
    });

    test('lets only the phone making a day change it', () async {
      final claimed =
          await claim('phone-a', proposal: _outfit('o1')) as DayClaimed;
      expect(
        await days.progress(
          'uid-1',
          claimed.day,
          piece: 2,
          pieces: 3,
          device: 'phone-b',
        ),
        const Right<Failure, bool>(false),
      );
      expect(
        await days.progress(
          'uid-1',
          claimed.day,
          piece: 2,
          pieces: 3,
          device: 'phone-a',
        ),
        const Right<Failure, bool>(true),
      );
      final day = await record('days/2026-10-18_work');
      expect((day?['piece'], day?['pieces']), (2, 3));
      expect(
        await days.fail(
          'uid-1',
          claimed.day,
          TryOnProblem.failed,
          device: 'phone-b',
        ),
        const Right<Failure, bool>(false),
      );
    });

    test('keeps a made picture on the phone and the account', () async {
      final claimed =
          await claim('phone-a', proposal: _outfit('o1')) as DayClaimed;
      final file = (await days.finish(
        'uid-1',
        claimed.day,
        _png,
        device: 'phone-a',
      )).getOrElse(() => null)!;
      expect(File(file).readAsBytesSync(), _png);
      expect(pictures.files.keys, ['users/uid-1/days/2026-10-18_work.png']);
      final day = await record('days/2026-10-18_work');
      expect(day?['status'], 'ready');
      expect(day?['picturePath'], 'users/uid-1/days/2026-10-18_work.png');
    });

    test('marks nothing made by a phone that lost the day', () async {
      final mine =
          await claim('phone-a', proposal: _outfit('o1')) as DayClaimed;
      time = time.add(DayRules.lease);
      await claim('phone-b');
      expect(
        await days.finish('uid-1', mine.day, _png, device: 'phone-a'),
        const Right<Failure, String?>(null),
      );
      expect((await record('days/2026-10-18_work'))?['status'], 'making');
    });

    test("fetches a made day's picture the phone lacks", () async {
      final claimed =
          await claim('phone-a', proposal: _outfit('o1')) as DayClaimed;
      await settled(days.finish('uid-1', claimed.day, _png, device: 'phone-a'));
      await days.forgetPictures('uid-1');
      final made = (await days.day(
        'uid-1',
        date: _tomorrow,
        occasion: Occasion.work,
      )).getOrElse(() => null)!;
      final file = (await days.picture(
        'uid-1',
        made,
      )).getOrElse(() => throw StateError('picture'));
      expect(File(file).readAsBytesSync(), _png);
    });

    test('follows a day as it changes', () async {
      final updates = days
          .watch('uid-1', date: _tomorrow, occasion: Occasion.work)
          .map((update) => update.getOrElse(() => null)?.status);
      final expectation = expectLater(
        updates,
        emitsInOrder([null, DayStatus.making, DayStatus.ready]),
      );
      final claimed =
          await claim('phone-a', proposal: _outfit('o1')) as DayClaimed;
      await days.finish('uid-1', claimed.day, _png, device: 'phone-a');
      await expectation;
    });
  });
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
