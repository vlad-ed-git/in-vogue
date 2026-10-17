import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/auth/domain/entities/account.dart';
import 'package:in_vogue/features/auth/domain/usecases/get_current_account.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_update.dart';
import 'package:in_vogue/features/makeup/domain/services/make_look.dart';
import 'package:in_vogue/features/makeup/domain/usecases/get_latest_makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/usecases/get_makeup_look.dart';
import 'package:in_vogue/features/makeup/presentation/bloc/makeup_bloc.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/usecases/get_kept_photo.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'makeup_bloc_test.mocks.dart';

DayOutfit _outfit(String signature, {Occasion occasion = Occasion.work}) =>
    DayOutfit(
      outfit: Outfit(
        id: signature,
        signature: signature,
        pieces: const ['everlane:tee'],
        passes: const [],
        palette: OutfitPalette.coolNeutral,
      ),
      date: DateTime.utc(2026, 10, 18),
      occasion: occasion,
      cell: 'cool|wet|calm|work',
      picture: '/support/outfits/uid-1/$signature.jpg',
    );

const _wet = WeatherClass(
  band: WarmthBand.cool,
  precipitation: Precipitation.wet,
  windy: false,
);
final _tomorrow = MakeupDay(
  day: ForecastDay.tomorrow,
  occasion: Occasion.work,
  outfit: _outfit('coat+tee'),
  weather: _wet,
);
final _today = MakeupDay(
  day: ForecastDay.today,
  occasion: Occasion.goingOut,
  outfit: _outfit('dress', occasion: Occasion.goingOut),
  weather: _wet,
);

MakeupLook _look(String signature) => MakeupLook(
  outfitSignature: signature,
  date: DateTime.utc(2026, 10, 18),
  occasion: Occasion.work,
  palette: OutfitPalette.coolNeutral,
  cheeks: CheekColour.rose,
  lips: LipColour.rosyNude,
  before: '/phone/$signature/before.png',
  steps: [
    LookStep(
      title: 'Even base',
      howTo: 'Blend it in.',
      products: const ['foundation in your shade'],
      picture: '/phone/$signature/step-1.jpg',
    ),
  ],
  matched: true,
);

const _face = UserPhoto(
  role: PhotoRole.face,
  path: '/support/photos/face-1.jpg',
  revision: 1,
);

const _pending = [
  LookStep(title: 'Even base', howTo: 'Blend it in.', products: []),
];
const _halfMade = [
  LookStep(
    title: 'Even base',
    howTo: 'Blend it in.',
    products: [],
    picture: '/phone/coat+tee/step-1.jpg',
  ),
];

@GenerateMocks([
  GetCurrentAccount,
  GetMakeupLook,
  GetLatestMakeupLook,
  GetKeptPhoto,
  MakeLook,
])
void main() {
  late MockGetCurrentAccount getCurrentAccount;
  late MockGetMakeupLook getMakeupLook;
  late MockGetLatestMakeupLook getLatestMakeupLook;
  late MockGetKeptPhoto getKeptPhoto;
  late MockMakeLook makeLook;

  MakeupBloc build() => MakeupBloc(
    getCurrentAccount: getCurrentAccount,
    getMakeupLook: getMakeupLook,
    getLatestMakeupLook: getLatestMakeupLook,
    getKeptPhoto: getKeptPhoto,
    makeLook: makeLook,
  );

  MakeupState ready(
    MakeupDay day, {
    MakeupLook? look,
    MakeupLook? lastLook,
    List<LookStep>? making,
    Failure? failure,
  }) => MakeupState(
    day: day,
    status: MakeupStatus.ready,
    look: look,
    lastLook: lastLook,
    making: making,
    failure: failure,
  );

  setUp(() {
    getCurrentAccount = MockGetCurrentAccount();
    getMakeupLook = MockGetMakeupLook();
    getLatestMakeupLook = MockGetLatestMakeupLook();
    getKeptPhoto = MockGetKeptPhoto();
    makeLook = MockMakeLook();
    provideDummy<Either<Failure, Account?>>(const Right(null));
    provideDummy<Either<Failure, MakeupLook?>>(const Right(null));
    provideDummy<Either<Failure, UserPhoto?>>(const Right(null));
    when(
      getKeptPhoto(PhotoRole.face),
    ).thenAnswer((_) async => const Right(_face));
    when(
      getCurrentAccount(any),
    ).thenAnswer((_) async => const Right(Account(id: 'uid-1')));
    when(getMakeupLook(any)).thenAnswer((_) async => const Right(null));
    when(getLatestMakeupLook(any)).thenAnswer((_) async => const Right(null));
    when(makeLook.underway(any)).thenAnswer((_) async => false);
  });

  blocTest<MakeupBloc, MakeupState>(
    'shows the look made for the outfit of the day',
    build: () {
      when(
        getMakeupLook(
          const MakeupLookParams(
            accountId: 'uid-1',
            outfitSignature: 'coat+tee',
          ),
        ),
      ).thenAnswer((_) async => Right(_look('coat+tee')));
      return build();
    },
    act: (bloc) => bloc.add(MakeupDayShown(_tomorrow)),
    expect: () => [
      MakeupState(day: _tomorrow),
      ready(_tomorrow, look: _look('coat+tee')),
    ],
    verify: (_) => verifyNever(getLatestMakeupLook(any)),
  );

  blocTest<MakeupBloc, MakeupState>(
    'makes the look by itself once there is a face photo and an outfit',
    build: () {
      when(
        getLatestMakeupLook('uid-1'),
      ).thenAnswer((_) async => Right(_look('dress')));
      when(makeLook(any)).thenAnswer(
        (_) => Stream.fromIterable([
          const MakeupProgress(_halfMade),
          MakeupDone(_look('coat+tee')),
        ]),
      );
      return build();
    },
    act: (bloc) => bloc.add(MakeupDayShown(_tomorrow)),
    expect: () => [
      MakeupState(day: _tomorrow),
      ready(_tomorrow, lastLook: _look('dress')),
      ready(_tomorrow, lastLook: _look('dress'), making: const []),
      ready(_tomorrow, lastLook: _look('dress'), making: _halfMade),
      ready(_tomorrow, look: _look('coat+tee')),
    ],
    verify: (_) => verify(
      makeLook(
        MakeLookParams(
          accountId: 'uid-1',
          outfit: _tomorrow.outfit!,
          weather: _wet,
        ),
      ),
    ).called(1),
  );

  blocTest<MakeupBloc, MakeupState>(
    'shows the last look below, and makes none, without a face photo',
    build: () {
      when(
        getKeptPhoto(PhotoRole.face),
      ).thenAnswer((_) async => const Right(null));
      when(
        getLatestMakeupLook('uid-1'),
      ).thenAnswer((_) async => Right(_look('dress')));
      return build();
    },
    act: (bloc) async {
      bloc.add(MakeupDayShown(_tomorrow));
      await pumpEventQueue();
      bloc.add(const MakeupRequested());
    },
    expect: () => [
      MakeupState(day: _tomorrow),
      ready(_tomorrow, lastLook: _look('dress')),
    ],
    verify: (_) => verifyNever(makeLook(any)),
  );

  blocTest<MakeupBloc, MakeupState>(
    'goes on by itself with a look cut short',
    build: () {
      when(makeLook.underway(any)).thenAnswer((_) async => true);
      when(makeLook(any)).thenAnswer(
        (_) => Stream.fromIterable([
          const MakeupProgress(_halfMade),
          MakeupDone(_look('coat+tee')),
        ]),
      );
      return build();
    },
    act: (bloc) => bloc.add(MakeupDayShown(_tomorrow)),
    expect: () => [
      MakeupState(day: _tomorrow),
      ready(_tomorrow),
      ready(_tomorrow, making: const []),
      ready(_tomorrow, making: _halfMade),
      ready(_tomorrow, look: _look('coat+tee')),
    ],
    verify: (_) => verify(
      makeLook(
        MakeLookParams(
          accountId: 'uid-1',
          outfit: _tomorrow.outfit!,
          weather: _wet,
        ),
      ),
    ).called(1),
  );

  blocTest<MakeupBloc, MakeupState>(
    'makes the look once the face photo is kept, filling in each step',
    build: () {
      when(makeLook(any)).thenAnswer(
        (_) => Stream.fromIterable([
          const MakeupProgress(_pending),
          const MakeupProgress(_halfMade),
          MakeupDone(_look('coat+tee')),
        ]),
      );
      return build();
    },
    seed: () => ready(_tomorrow, lastLook: _look('dress')),
    act: (bloc) => bloc.add(const MakeupRequested()),
    expect: () => [
      ready(_tomorrow, lastLook: _look('dress'), making: const []),
      ready(_tomorrow, lastLook: _look('dress'), making: _pending),
      ready(_tomorrow, lastLook: _look('dress'), making: _halfMade),
      ready(_tomorrow, look: _look('coat+tee')),
    ],
  );

  blocTest<MakeupBloc, MakeupState>(
    'says what went wrong, and asks again on Try again',
    build: () {
      var asked = 0;
      when(makeLook(any)).thenAnswer(
        (_) => Stream.fromIterable([
          if (asked++ == 0)
            const MakeupFailed(MakeupFailure(MakeupProblem.failed))
          else
            MakeupDone(_look('coat+tee')),
        ]),
      );
      return build();
    },
    seed: () => ready(_tomorrow),
    act: (bloc) async {
      bloc.add(const MakeupRequested());
      await pumpEventQueue();
      bloc.add(const MakeupRequested());
    },
    expect: () => [
      ready(_tomorrow, making: const []),
      ready(_tomorrow, failure: const MakeupFailure(MakeupProblem.failed)),
      ready(_tomorrow, making: const []),
      ready(_tomorrow, look: _look('coat+tee')),
    ],
  );

  blocTest<MakeupBloc, MakeupState>(
    'makes nothing by itself again after a failure',
    build: build,
    seed: () =>
        ready(_tomorrow, failure: const MakeupFailure(MakeupProblem.failed)),
    act: (bloc) => bloc.add(MakeupDayShown(_tomorrow)),
    expect: () => <MakeupState>[],
    verify: (_) => verifyNever(makeLook(any)),
  );

  blocTest<MakeupBloc, MakeupState>(
    'has nothing to make without an outfit',
    build: build,
    act: (bloc) async {
      bloc.add(
        const MakeupDayShown(
          MakeupDay(day: ForecastDay.tomorrow, outfitPending: true),
        ),
      );
      await pumpEventQueue();
      bloc.add(const MakeupRequested());
    },
    expect: () => [
      const MakeupState(
        day: MakeupDay(day: ForecastDay.tomorrow, outfitPending: true),
      ),
      ready(const MakeupDay(day: ForecastDay.tomorrow, outfitPending: true)),
    ],
    verify: (_) {
      verifyNever(getMakeupLook(any));
      verifyNever(makeLook(any));
    },
  );

  blocTest<MakeupBloc, MakeupState>(
    'keeps the look when only the weather of its outfit changes',
    build: () {
      when(
        getMakeupLook(any),
      ).thenAnswer((_) async => Right(_look('coat+tee')));
      return build();
    },
    act: (bloc) async {
      bloc.add(MakeupDayShown(_tomorrow));
      await pumpEventQueue();
      bloc.add(
        MakeupDayShown(
          MakeupDay(
            day: ForecastDay.tomorrow,
            occasion: Occasion.work,
            outfit: _tomorrow.outfit,
          ),
        ),
      );
    },
    skip: 2,
    expect: () => [
      ready(
        MakeupDay(
          day: ForecastDay.tomorrow,
          occasion: Occasion.work,
          outfit: _tomorrow.outfit,
        ),
        look: _look('coat+tee'),
      ),
    ],
    verify: (_) => verify(getMakeupLook(any)).called(1),
  );

  blocTest<MakeupBloc, MakeupState>(
    "never shows one outfit's look on another outfit's day",
    build: () {
      final making = StreamController<MakeupUpdate>();
      addTearDown(making.close);
      when(makeLook(any)).thenAnswer((invocation) {
        final params = invocation.positionalArguments.first as MakeLookParams;
        return params.outfit == _tomorrow.outfit
            ? making.stream
            : const Stream.empty();
      });
      when(getMakeupLook(any)).thenAnswer((invocation) async {
        // Updates for tomorrow's look arrive once today is shown.
        making
          ..add(const MakeupProgress(_halfMade))
          ..add(MakeupDone(_look('coat+tee')));
        return const Right(null);
      });
      return build();
    },
    seed: () => ready(_tomorrow),
    act: (bloc) async {
      bloc.add(const MakeupRequested());
      await pumpEventQueue();
      bloc.add(MakeupDayShown(_today));
    },
    expect: () => [
      ready(_tomorrow, making: const []),
      MakeupState(day: _today),
      ready(_today),
      ready(_today, making: const []),
    ],
  );
}
