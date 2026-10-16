import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_pieces_for_weather.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/picks_bloc.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'picks_bloc_test.mocks.dart';

const _coat = Piece(
  id: 'coat',
  name: 'The Wool Coat',
  category: PieceCategory.outerwear,
  bands: {WarmthBand.cool},
  colourways: [
    Colourway(
      id: 'coat-camel',
      name: 'Camel',
      hex: 0xFFAB9073,
      photoUrl: 'https://cdn.example/coat-camel.jpg',
      productUrl: 'https://shop.example/coat-camel',
    ),
  ],
);
const _tee = Piece(
  id: 'tee',
  name: 'The Organic Tee',
  category: PieceCategory.top,
  bands: {WarmthBand.hot},
  colourways: [
    Colourway(
      id: 'tee-white',
      name: 'White',
      hex: 0xFFFFFFFF,
      photoUrl: 'https://cdn.example/tee-white.jpg',
      productUrl: 'https://shop.example/tee-white',
    ),
  ],
);

@GenerateMocks([CatalogRepository, PicksRepository])
void main() {
  late MockCatalogRepository catalog;
  late MockPicksRepository picks;

  PicksBloc buildBloc() => PicksBloc(
    getPiecesForWeather: GetPiecesForWeather(catalog),
    getPicks: GetPicks(picks),
    setPick: SetPick(picks),
  );

  setUp(() {
    catalog = MockCatalogRepository();
    picks = MockPicksRepository();
    when(catalog.pieces()).thenAnswer((_) async => const Right([_coat, _tee]));
    when(picks.picks()).thenAnswer((_) async => const Right({'tee-white'}));
    when(picks.setPick(any, loved: anyNamed('loved'))).thenAnswer(
      (invocation) async => Right({
        if (invocation.namedArguments[#loved] == true)
          invocation.positionalArguments.first as String,
      }),
    );
  });

  test('starts loading with no picks', () {
    expect(buildBloc().state, const PicksState());
  });

  blocTest<PicksBloc, PicksState>(
    'shows the pieces for the weather and the saved picks',
    build: buildBloc,
    act: (bloc) => bloc.add(const PicksRequested(WarmthBand.cool)),
    expect: () => [
      const PicksState(
        status: PicksStatus.ready,
        pieces: [_coat],
        picks: {'tee-white'},
      ),
    ],
  );

  blocTest<PicksBloc, PicksState>(
    'says when the collection cannot be read',
    build: () {
      when(
        catalog.pieces(),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      return buildBloc();
    },
    act: (bloc) => bloc.add(const PicksRequested(WarmthBand.cool)),
    expect: () => [const PicksState(status: PicksStatus.failed)],
  );

  blocTest<PicksBloc, PicksState>(
    'loves a colourway at once and keeps what was saved',
    build: buildBloc,
    seed: () => const PicksState(status: PicksStatus.ready, pieces: [_coat]),
    act: (bloc) => bloc.add(const PickToggled('coat-camel', loved: true)),
    expect: () => [
      const PicksState(
        status: PicksStatus.ready,
        pieces: [_coat],
        picks: {'coat-camel'},
      ),
    ],
    verify: (_) => verify(picks.setPick('coat-camel', loved: true)).called(1),
  );

  blocTest<PicksBloc, PicksState>(
    'takes a pick back when it cannot be saved',
    build: () {
      when(
        picks.setPick(any, loved: anyNamed('loved')),
      ).thenAnswer((_) async => const Left(CacheFailure()));
      return buildBloc();
    },
    seed: () => const PicksState(status: PicksStatus.ready, pieces: [_coat]),
    act: (bloc) => bloc.add(const PickToggled('coat-camel', loved: true)),
    expect: () => [
      const PicksState(
        status: PicksStatus.ready,
        pieces: [_coat],
        picks: {'coat-camel'},
      ),
      const PicksState(
        status: PicksStatus.ready,
        pieces: [_coat],
        failure: CacheFailure(),
      ),
    ],
  );

  test('saves quick taps in order', () async {
    final first = Completer<Either<Failure, Set<String>>>();
    when(
      picks.setPick('coat-camel', loved: true),
    ).thenAnswer((_) => first.future);
    when(
      picks.setPick('coat-camel', loved: false),
    ).thenAnswer((_) async => const Right(<String>{}));
    final bloc = buildBloc();
    addTearDown(bloc.close);
    bloc
      ..add(const PickToggled('coat-camel', loved: true))
      ..add(const PickToggled('coat-camel', loved: false));
    await Future<void>.delayed(Duration.zero);
    verifyNever(picks.setPick('coat-camel', loved: false));
    first.complete(const Right({'coat-camel'}));
    await bloc.stream.firstWhere((state) => state.picks.isEmpty);
    verifyInOrder([
      picks.setPick('coat-camel', loved: true),
      picks.setPick('coat-camel', loved: false),
    ]);
  });
}
