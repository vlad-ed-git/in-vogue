import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_shop_pieces.dart';
import 'package:in_vogue/features/home/presentation/bloc/shop_bloc.dart';
import 'package:in_vogue/features/home/presentation/screens/shop_screen.dart';

import '../../helpers/catalog_outfits.dart';
import '../../helpers/pump_in_vogue.dart';

class _MockShopBloc extends MockBloc<ShopEvent, ShopState>
    implements ShopBloc {}

const _coat = Colourway(
  id: 'everlane:coat',
  name: 'Coffee Bean',
  hex: 0xFF2D221C,
  photoUrl: 'https://cdn.example/coat-worn.jpg',
  flatUrl: 'https://cdn.example/coat-flat.jpg',
  productUrl: 'https://www.everlane.com/products/coat',
  material: '100% organic cotton',
);
const _jeans = Colourway(
  id: 'everlane:jeans',
  name: 'Navy',
  hex: 0xFF262B38,
  photoUrl: 'https://cdn.example/jeans-worn.jpg',
  productUrl: 'https://www.everlane.com/products/jeans',
);

Piece _piece(String name, Colourway colourway) =>
    Piece(id: colourway.id, name: name, colourways: [colourway]);

final _pieces = [
  ShopPiece(piece: _piece('Oversized Mac Coat', _coat), colourway: _coat),
  ShopPiece(piece: _piece('The Way-High Jean', _jeans), colourway: _jeans),
];

class _Catalog implements CatalogRepository {
  @override
  Future<Either<Failure, List<Piece>>> pieces() async =>
      Right([for (final item in _pieces) item.piece]);

  @override
  Future<Either<Failure, String>> brand() async => const Right('Everlane');
}

void main() {
  late List<Uri> opened;
  late List<String> images;

  setUp(() {
    opened = [];
    images = [];
  });

  Future<void> pumpShop(WidgetTester tester, ShopState state) async {
    final bloc = _MockShopBloc();
    whenListen(bloc, const Stream<ShopState>.empty(), initialState: state);
    await pumpInVogue(
      tester,
      BlocProvider<ShopBloc>.value(
        value: bloc,
        child: ShopScreen(
          onBack: () {},
          openLink: (link) async {
            opened.add(link);
            return true;
          },
          imageFor: (url) {
            images.add(url);
            return testImage;
          },
        ),
      ),
      scroll: false,
    );
    await tester.pump();
  }

  testWidgets('lists every piece with its colour, material and shop link', (
    tester,
  ) async {
    await pumpShop(
      tester,
      ShopState(status: ShopStatus.ready, brand: 'Everlane', pieces: _pieces),
    );
    expect(find.text('Shop this outfit'), findsOneWidget);
    expect(find.text('Oversized Mac Coat'), findsOneWidget);
    expect(find.text('Coffee Bean'), findsOneWidget);
    expect(find.text('100% organic cotton'), findsOneWidget);
    expect(find.text('The Way-High Jean'), findsOneWidget);
    expect(find.text('Buy at Everlane'), findsNWidgets(2));
    // The flat-lay first; the worn photo when there is none.
    expect(images, [
      'https://cdn.example/coat-flat.jpg',
      'https://cdn.example/jeans-worn.jpg',
    ]);
    final coat = tester.getTopLeft(find.text('Oversized Mac Coat'));
    final jeans = tester.getTopLeft(find.text('The Way-High Jean'));
    expect(coat.dy, lessThan(jeans.dy));
  });

  testWidgets('opens that exact piece and colour at the partner', (
    tester,
  ) async {
    await pumpShop(
      tester,
      ShopState(status: ShopStatus.ready, brand: 'Everlane', pieces: _pieces),
    );
    await tester.tap(find.text('Buy at Everlane').last);
    expect(opened, [Uri.parse('https://www.everlane.com/products/jeans')]);
  });

  testWidgets('never shows a price', (tester) async {
    await pumpShop(
      tester,
      ShopState(status: ShopStatus.ready, brand: 'Everlane', pieces: _pieces),
    );
    expect(find.textContaining(r'$'), findsNothing);
  });

  testWidgets('says when the pieces cannot be read', (tester) async {
    await pumpShop(tester, const ShopState(status: ShopStatus.failed));
    expect(find.byType(Notice), findsOneWidget);
    expect(find.byType(ShopItem), findsNothing);
  });

  group('GetShopPieces', () {
    test('finds the colourways in order, leaving out unknown ones', () async {
      final found = await GetShopPieces(_Catalog())(const [
        'everlane:jeans',
        'everlane:gone',
        'everlane:coat',
      ]);
      final shop = found.getOrElse(() => throw StateError('found'));
      expect(shop.brand, 'Everlane');
      expect([for (final item in shop.pieces) item.colourway], [_jeans, _coat]);
    });
  });

  group('ShopBloc', () {
    blocTest<ShopBloc, ShopState>(
      'shows the pieces asked for',
      build: () => ShopBloc(
        getShopPieces: GetShopPieces(_Catalog()),
        getOutfitShop: GetOutfitShop(_Catalog()),
      ),
      act: (bloc) => bloc.add(const ShopRequested(['everlane:coat'])),
      expect: () => [
        ShopState(
          status: ShopStatus.ready,
          brand: 'Everlane',
          pieces: [_pieces.first],
        ),
      ],
    );

    blocTest<ShopBloc, ShopState>(
      'shows a catalog outfit’s pieces, outer layer first',
      build: () => ShopBloc(
        getShopPieces: GetShopPieces(_Catalog()),
        getOutfitShop: GetOutfitShop(_Catalog()),
      ),
      act: (bloc) => bloc.add(ShopOutfitRequested(outfit('o1'))),
      verify: (bloc) {
        expect(bloc.state.status, ShopStatus.ready);
        expect(
          [for (final item in bloc.state.pieces) item.colourway.name],
          ['Parchment', 'Bone'],
        );
      },
    );
  });
}
