import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/catalog/domain/repositories/outfit_catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/stylist/domain/entities/taste_signal.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/catalog_outfits.dart';
import '../../helpers/taste.dart';
import 'picks_bloc_test.mocks.dart';

final _sample = [outfit('o1', sample: true), outfit('o2', sample: true)];
final _catalog = [
  for (var i = 0; i < 25; i++)
    outfit('c$i', order: i, weathers: i < 3 ? ['freezing'] : ['warm']),
];

@GenerateMocks([OutfitCatalogRepository, PicksRepository])
void main() {
  late MemoryTaste taste;
  late MockOutfitCatalogRepository catalog;
  late MockPicksRepository picks;

  PicksBloc buildBloc() => PicksBloc(
    getSampleOutfits: GetSampleOutfits(catalog),
    getCatalogPage: GetCatalogPage(catalog),
    getPicks: GetPicks(picks),
    setPick: SetPick(picks),
    recordSignal: recordSignalInto(taste),
  );

  setUp(() {
    taste = MemoryTaste();
    catalog = MockOutfitCatalogRepository();
    picks = MockPicksRepository();
    when(catalog.sample()).thenAnswer((_) async => Right(_sample));
    when(catalog.outfits()).thenAnswer((_) async => Right(_catalog));
    when(picks.picks()).thenAnswer((_) async => const Right({'o2'}));
  });

  List<String> ids(PicksState state) => [
    for (final outfit in state.outfits) outfit.id,
  ];

  blocTest<PicksBloc, PicksState>(
    'shows the sample with the saved picks',
    build: buildBloc,
    act: (bloc) => bloc.add(const PicksRequested.sample()),
    expect: () => [
      const PicksState(),
      PicksState(
        status: PicksStatus.ready,
        outfits: _sample,
        picks: const {'o2'},
      ),
    ],
  );

  blocTest<PicksBloc, PicksState>(
    'says why the sample could not be read',
    build: buildBloc,
    setUp: () => when(
      catalog.sample(),
    ).thenAnswer((_) async => const Left(NetworkFailure())),
    act: (bloc) => bloc.add(const PicksRequested.sample()),
    skip: 1,
    expect: () => [
      const PicksState(
        status: PicksStatus.failed,
        picks: {'o2'},
        loadFailure: NetworkFailure(),
      ),
    ],
  );

  blocTest<PicksBloc, PicksState>(
    'shows the catalog a page at a time',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const PicksRequested.catalog());
      await Future<void>.delayed(Duration.zero);
      bloc
        ..add(const PicksMoreRequested())
        ..add(const PicksMoreRequested());
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(ids(bloc.state), [for (var i = 0; i < 25; i++) 'c$i']);
      expect(bloc.state.hasMore, isFalse);
    },
  );

  blocTest<PicksBloc, PicksState>(
    'a weather chip starts the list again with that weather’s outfits',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const PicksRequested.catalog());
      await Future<void>.delayed(Duration.zero);
      bloc.add(
        const PicksRequested.catalog(
          CatalogFilter.weather(WarmthBand.freezing),
        ),
      );
    },
    wait: const Duration(milliseconds: 10),
    verify: (bloc) {
      expect(
        bloc.state.filter,
        const CatalogFilter.weather(WarmthBand.freezing),
      );
      expect(ids(bloc.state), ['c0', 'c1', 'c2']);
      expect(bloc.state.hasMore, isFalse);
    },
  );

  blocTest<PicksBloc, PicksState>(
    'a heart shows at once and stays when saved',
    build: buildBloc,
    seed: () => PicksState(status: PicksStatus.ready, outfits: _sample),
    setUp: () => when(
      picks.setPick('o1', loved: true),
    ).thenAnswer((_) async => const Right({'o1'})),
    act: (bloc) => bloc.add(const PickToggled('o1', loved: true)),
    expect: () => [
      PicksState(
        status: PicksStatus.ready,
        outfits: _sample,
        picks: const {'o1'},
      ),
    ],
  );

  blocTest<PicksBloc, PicksState>(
    'a heart that can’t be saved is taken back, saying why',
    build: buildBloc,
    seed: () => PicksState(
      status: PicksStatus.ready,
      outfits: _sample,
      picks: const {'o2'},
    ),
    setUp: () => when(
      picks.setPick('o2', loved: false),
    ).thenAnswer((_) async => const Left(CacheFailure())),
    act: (bloc) => bloc.add(const PickToggled('o2', loved: false)),
    expect: () => [
      PicksState(status: PicksStatus.ready, outfits: _sample),
      PicksState(
        status: PicksStatus.ready,
        outfits: _sample,
        picks: const {'o2'},
        failure: const CacheFailure(),
      ),
    ],
  );

  group('teaches the taste model', () {
    setUp(() {
      when(
        picks.setPick(any, loved: anyNamed('loved')),
      ).thenAnswer((_) async => const Right({}));
    });

    Future<List<(TasteSignalKind, String?)>> signals(
      PicksEvent shown,
      List<PickToggled> toggles,
    ) async {
      final bloc = buildBloc()..add(shown);
      await Future<void>.delayed(Duration.zero);
      for (final toggle in toggles) {
        bloc.add(toggle);
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await bloc.close();
      return [for (final signal in taste.phone) (signal.kind, signal.outfitId)];
    }

    test('a heart in setup is a pick; on Home, a love', () async {
      expect(
        await signals(const PicksRequested.sample(), [
          const PickToggled('o1', loved: true),
        ]),
        [(TasteSignalKind.picked, 'o1')],
      );
      taste.phone.clear();
      expect(
        await signals(const PicksRequested.catalog(), [
          const PickToggled('c3', loved: true),
          const PickToggled('c3', loved: false),
        ]),
        [(TasteSignalKind.loved, 'c3'), (TasteSignalKind.unloved, 'c3')],
      );
    });

    test('a heart that can’t be saved teaches nothing', () async {
      when(
        picks.setPick('o1', loved: true),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      expect(
        await signals(const PicksRequested.sample(), [
          const PickToggled('o1', loved: true),
        ]),
        isEmpty,
      );
    });
  });

  test('the sample never asks for more pages', () async {
    final bloc = buildBloc()..add(const PicksRequested.sample());
    await Future<void>.delayed(Duration.zero);
    bloc.add(const PicksMoreRequested());
    await Future<void>.delayed(Duration.zero);
    verifyNever(catalog.outfits());
    expect(bloc.state.outfits, <CatalogOutfit>[..._sample]);
    await bloc.close();
  });
}
