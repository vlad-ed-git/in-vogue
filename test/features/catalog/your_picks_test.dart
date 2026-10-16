import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/repositories/picks_repository.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_picks.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_shop_pieces.dart';
import 'package:in_vogue/features/catalog/domain/usecases/set_pick.dart';
import 'package:in_vogue/features/catalog/presentation/bloc/your_picks_bloc.dart';
import 'package:in_vogue/features/catalog/presentation/screens/your_picks_screen.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_in_vogue.dart';

Colourway _colourway(String id, String name) => Colourway(
  id: id,
  name: name,
  hex: 0xFF222222,
  photoUrl: 'https://cdn.example/$id.jpg',
  productUrl: 'https://www.everlane.com/products/$id',
);

final _dress = Piece(
  id: 'dress',
  name: 'The Satin Slip Dress',
  category: PieceCategory.dress,
  bands: const {WarmthBand.warm},
  colourways: [_colourway('everlane:dress-black', 'Black')],
);
final _tee = Piece(
  id: 'tee',
  name: 'The Organic Cotton Tee',
  category: PieceCategory.top,
  bands: const {WarmthBand.mild},
  colourways: [
    _colourway('everlane:tee-white', 'White'),
    _colourway('everlane:tee-navy', 'Navy'),
  ],
);

class _Catalog implements CatalogRepository {
  @override
  Future<Either<Failure, List<Piece>>> pieces() async => Right([_dress, _tee]);

  @override
  Future<Either<Failure, String>> brand() async => const Right('Everlane');
}

/// Picks in the order they were loved.
class _Picks implements PicksRepository {
  _Picks(this.loved);
  final List<String> loved;

  @override
  Future<Either<Failure, Set<String>>> picks() async => Right({...loved});

  @override
  Future<Either<Failure, Set<String>>> setPick(
    String colourwayId, {
    required bool loved,
  }) async {
    loved ? this.loved.add(colourwayId) : this.loved.remove(colourwayId);
    return Right({...this.loved});
  }
}

void main() {
  late _Picks picks;

  YourPicksBloc buildBloc() => YourPicksBloc(
    getPicks: GetPicks(picks),
    getShopPieces: GetShopPieces(_Catalog()),
    setPick: SetPick(picks),
  );

  setUp(() => picks = _Picks(['everlane:tee-white', 'everlane:dress-black']));

  blocTest<YourPicksBloc, YourPicksState>(
    'shows only the loved colourways, the latest first',
    build: buildBloc,
    act: (bloc) => bloc.add(const YourPicksLoaded()),
    expect: () => [
      YourPicksState(
        status: YourPicksStatus.ready,
        picks: [
          ShopPiece(piece: _dress, colourway: _dress.colourways.first),
          ShopPiece(piece: _tee, colourway: _tee.colourways.first),
        ],
      ),
    ],
  );

  blocTest<YourPicksBloc, YourPicksState>(
    'removes a pick once it is confirmed',
    build: buildBloc,
    act: (bloc) async {
      bloc.add(const YourPicksLoaded());
      await bloc.stream.first;
      bloc.add(const YourPickRemoved('everlane:dress-black'));
    },
    skip: 1,
    expect: () => [
      YourPicksState(
        status: YourPicksStatus.ready,
        picks: [ShopPiece(piece: _tee, colourway: _tee.colourways.first)],
      ),
    ],
    verify: (_) => expect(picks.loved, ['everlane:tee-white']),
  );

  group('YourPicksScreen', () {
    late _MockYourPicksBloc bloc;

    setUpAll(() => registerFallbackValue(const YourPicksLoaded()));

    Future<void> pumpScreen(
      WidgetTester tester, {
      List<ShopPiece>? shown,
    }) async {
      bloc = _MockYourPicksBloc();
      whenListen(
        bloc,
        const Stream<YourPicksState>.empty(),
        initialState: YourPicksState(
          status: YourPicksStatus.ready,
          picks:
              shown ??
              [
                ShopPiece(piece: _dress, colourway: _dress.colourways.first),
                ShopPiece(piece: _tee, colourway: _tee.colourways.first),
              ],
        ),
      );
      await pumpInVogue(
        tester,
        BlocProvider<YourPicksBloc>.value(
          value: bloc,
          child: YourPicksScreen(onBack: () {}, imageFor: (_) => testImage),
        ),
        scroll: false,
      );
      await tester.pump();
    }

    Future<void> openRemoval(WidgetTester tester) async {
      await tester.tap(find.bySemanticsLabel('Love The Satin Slip Dress'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }

    testWidgets('shows the picks and nothing else', (tester) async {
      await pumpScreen(tester);
      expect(find.text('Your picks'), findsOneWidget);
      expect(find.byType(ProductTile), findsNWidgets(2));
      expect(find.text('The Satin Slip Dress'), findsOneWidget);
      expect(find.text('The Organic Cotton Tee'), findsOneWidget);
      expect(find.byType(WeatherLine), findsNothing);
      expect(find.textContaining(r'$'), findsNothing);
    });

    testWidgets('asks before removing a pick, and keeps it on Keep', (
      tester,
    ) async {
      await pumpScreen(tester);
      await openRemoval(tester);
      expect(find.text('Remove from your picks?'), findsOneWidget);
      await tester.tap(find.text('Keep'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Remove from your picks?'), findsNothing);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('removes a pick on Remove', (tester) async {
      await pumpScreen(tester);
      await openRemoval(tester);
      await tester.tap(find.text('Remove'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      verify(
        () => bloc.add(const YourPickRemoved('everlane:dress-black')),
      ).called(1);
    });

    testWidgets('says when nothing is picked yet', (tester) async {
      await pumpScreen(tester, shown: const []);
      expect(find.text('You haven’t picked anything yet.'), findsOneWidget);
      expect(find.byType(ProductTile), findsNothing);
    });
  });
}

class _MockYourPicksBloc extends MockBloc<YourPicksEvent, YourPicksState>
    implements YourPicksBloc {}
