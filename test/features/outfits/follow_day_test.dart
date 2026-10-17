import 'dart:async';

import 'package:clock/clock.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/install_id.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/domain/entities/day.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_update.dart';
import 'package:in_vogue/features/outfits/domain/repositories/day_repository.dart';
import 'package:in_vogue/features/outfits/domain/repositories/outfit_repository.dart';
import 'package:in_vogue/features/outfits/domain/services/day_rules.dart';
import 'package:in_vogue/features/outfits/domain/services/follow_day.dart';
import 'package:in_vogue/features/outfits/domain/services/make_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'follow_day_test.mocks.dart';

final _now = DateTime.utc(2026, 10, 17, 8);
final _params = MakeOutfitParams(
  accountId: 'uid-1',
  date: DateTime.utc(2026, 10, 18),
  occasion: Occasion.work,
  weatherClass: const WeatherClass(
    band: WarmthBand.cool,
    precipitation: Precipitation.dry,
    windy: false,
  ),
);

const _dress = Outfit(
  id: 'o2',
  signature: 'dress',
  pieces: ['everlane:dress'],
  passes: [],
);

Day _day(String device, {Duration ago = Duration.zero}) => Day(
  date: DateTime.utc(2026, 10, 18),
  occasion: Occasion.work,
  cell: 'cool|dry|calm|work',
  outfitId: 'o2',
  signature: 'dress',
  status: DayStatus.making,
  device: device,
  piece: 1,
  pieces: 2,
  updatedAt: _now.subtract(ago),
);

final _made = DayOutfit(
  outfit: _dress,
  date: DateTime.utc(2026, 10, 18),
  occasion: Occasion.work,
  cell: 'cool|dry|calm|work',
  picture: '/phone/uid-1/2026-10-18_work.jpg',
);

@GenerateMocks([MakeOutfit])
void main() {
  late _FakeDays days;
  late MockMakeOutfit makeOutfit;
  late StreamController<TryOnUpdate> making;
  late FollowDay follow;
  late List<TryOnUpdate> updates;
  late StreamSubscription<TryOnUpdate> subscription;

  setUp(() {
    days = _FakeDays();
    makeOutfit = MockMakeOutfit();
    making = StreamController<TryOnUpdate>.broadcast();
    when(makeOutfit(any)).thenAnswer((_) => making.stream);
    follow = FollowDay(
      days: days,
      outfits: _FakeOutfits(),
      makeOutfit: makeOutfit,
      installId: const InstallId('phone-a'),
    );
    updates = [];
  });

  tearDown(() async {
    await subscription.cancel();
    await making.close();
  });

  Future<void> start() async {
    subscription = withClock(
      Clock.fixed(_now),
      () => follow(_params).listen(updates.add),
    );
    await pumpEventQueue();
  }

  Future<void> watched(Day? day) async {
    await withClock(Clock.fixed(_now), () async {
      days.days.add(Right(day));
      await pumpEventQueue();
    });
  }

  test('makes a day that has no outfit, and follows its making', () async {
    await start();
    await watched(null);
    verify(makeOutfit(_params)).called(1);
    making
      ..add(const TryOnProgress(piece: 1, pieces: 2))
      ..add(TryOnDone(_made));
    await pumpEventQueue();
    expect(updates, [
      const TryOnProgress(piece: 1, pieces: 2),
      TryOnDone(_made),
    ]);
  });

  test('shows a day another phone made, making nothing', () async {
    await start();
    await watched(_day('phone-b').readyAt('users/uid-1/days/x.jpg'));
    expect(updates, [TryOnDone(_made)]);
    verifyNever(makeOutfit(any));
  });

  test("shows another phone's progress, making nothing", () async {
    await start();
    await watched(_day('phone-b').progressing(2, 3));
    expect(updates, [const TryOnProgress(piece: 2, pieces: 3)]);
    verifyNever(makeOutfit(any));
  });

  test("takes over another phone's making once it goes stale", () async {
    await start();
    await watched(_day('phone-b', ago: DayRules.lease));
    verify(makeOutfit(_params)).called(1);
  });

  test("goes on with this phone's making when it stopped", () async {
    await start();
    await watched(_day('phone-a'));
    verify(makeOutfit(_params)).called(1);
    await watched(_day('phone-a').progressing(2, 2));
    verifyNever(makeOutfit(any));
  });

  test('makes nothing again after a failure, until asked', () async {
    await start();
    await watched(null);
    making.add(const TryOnFailed(NetworkFailure()));
    await pumpEventQueue();
    await watched(null);
    verify(makeOutfit(_params)).called(1);
    expect(updates, [const TryOnFailed(NetworkFailure())]);

    follow.retry(_params);
    await pumpEventQueue();
    verify(makeOutfit(_params)).called(1);
  });

  test('shows a failed day, and makes it again when asked', () async {
    await start();
    await watched(_day('phone-b').failedWith(TryOnProblem.photo));
    expect(updates, [const TryOnFailed(TryOnFailure(TryOnProblem.photo))]);
    verifyNever(makeOutfit(any));
    follow.retry(_params);
    await pumpEventQueue();
    verify(makeOutfit(_params)).called(1);
  });

  test('stays done once done', () async {
    await start();
    await watched(null);
    making.add(TryOnDone(_made));
    await pumpEventQueue();
    await watched(_day('phone-a'));
    expect(updates, [TryOnDone(_made)]);
  });

  test('says when the day cannot be followed', () async {
    await start();
    days.days.add(const Left(NetworkFailure()));
    await pumpEventQueue();
    expect(updates, [const TryOnFailed(NetworkFailure())]);
  });
}

class _FakeDays implements DayRepository {
  final days = StreamController<Either<Failure, Day?>>();

  @override
  Stream<Either<Failure, Day?>> watch(
    String accountId, {
    required DateTime date,
    required Occasion occasion,
  }) => days.stream;

  @override
  Future<Either<Failure, String>> picture(String accountId, Day day) async =>
      const Right('/phone/uid-1/2026-10-18_work.jpg');

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _FakeOutfits implements OutfitRepository {
  @override
  Future<Either<Failure, Outfit?>> outfit(String id) async =>
      Right(id == _dress.id ? _dress : null);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}
