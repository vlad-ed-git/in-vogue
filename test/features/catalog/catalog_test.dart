import 'package:dartz/dartz.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/catalog/data/data_sources/catalog_asset_data_source.dart';
import 'package:in_vogue/features/catalog/data/data_sources/picks_local_data_source.dart';
import 'package:in_vogue/features/catalog/data/models/piece_model.dart';
import 'package:in_vogue/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:in_vogue/features/catalog/data/repositories/picks_repository_impl.dart';
import 'package:in_vogue/features/catalog/domain/entities/piece.dart';
import 'package:in_vogue/features/catalog/domain/usecases/get_pieces_for_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../helpers/memory_store.dart';
import 'catalog_test.mocks.dart';

Piece _piece(String id, PieceCategory category, Set<WarmthBand> bands) => Piece(
  id: id,
  name: id,
  category: category,
  bands: bands,
  colourways: [
    Colourway(
      id: '$id-1',
      name: 'Black',
      hex: 0xFF000000,
      photoUrl: 'https://cdn.example/$id.jpg',
      productUrl: 'https://shop.example/$id',
    ),
  ],
);

@GenerateMocks([CatalogAssetDataSource])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WarmthBand', () {
    test('follows the knowledge base’s feels-like bands', () {
      expect(WarmthBand.forFeelsLike(26), WarmthBand.hot);
      expect(WarmthBand.forFeelsLike(25.9), WarmthBand.warm);
      expect(WarmthBand.forFeelsLike(20), WarmthBand.warm);
      expect(WarmthBand.forFeelsLike(19.9), WarmthBand.mild);
      expect(WarmthBand.forFeelsLike(14), WarmthBand.mild);
      expect(WarmthBand.forFeelsLike(13.9), WarmthBand.cool);
      expect(WarmthBand.forFeelsLike(8), WarmthBand.cool);
      expect(WarmthBand.forFeelsLike(7.9), WarmthBand.cold);
    });
  });

  group('PieceModel', () {
    test('reads a piece with its colourways and bands', () {
      final piece = PieceModel.fromJson({
        'id': 'trench',
        'name': 'The Trench',
        'category': 'outerwear',
        'bands': ['mild', 'cool'],
        'colourways': [
          {
            'id': 'everlane:trench-khaki',
            'name': 'Khaki',
            'hex': '#c3b091',
            'photo': 'https://cdn.example/trench.jpg',
            'flat': null,
            'url': 'https://shop.example/trench-khaki',
          },
        ],
      });
      expect(piece.category, PieceCategory.outerwear);
      expect(piece.bands, {WarmthBand.mild, WarmthBand.cool});
      expect(piece.colourways.single.hex, 0xFFC3B091);
      expect(piece.colourways.single.flatUrl, isNull);
      expect(piece.waterResistant, isFalse);
    });

    test('knows a piece documented as water-resistant', () {
      final piece = PieceModel.fromJson({
        'id': 'mac',
        'name': 'The Mac',
        'category': 'outerwear',
        'bands': ['cool'],
        'rain': true,
        'colourways': <Object?>[],
      });
      expect(piece.waterResistant, isTrue);
    });

    test('rejects an entry that is not a piece', () {
      expect(
        () => PieceModel.fromJson({'id': 'x', 'category': 'hat'}),
        throwsFormatException,
      );
    });
  });

  test('the bundled catalog has every piece with a photo', () async {
    final pieces = await CatalogAssetDataSourceImpl(rootBundle).pieces();
    expect(pieces, hasLength(623));
    expect(pieces.where((piece) => piece.waterResistant), hasLength(12));
    for (final piece in pieces) {
      expect(piece.colourways, isNotEmpty);
      expect(piece.bands, isNotEmpty);
      for (final colourway in piece.colourways) {
        expect(Uri.parse(colourway.photoUrl).host, 'cdn.shopify.com');
      }
    }
  });

  group('CatalogRepositoryImpl', () {
    test('reads the catalog once and reports a broken one', () async {
      final asset = MockCatalogAssetDataSource();
      final pieces = [
        _piece('a', PieceCategory.top, {WarmthBand.mild}),
      ];
      when(asset.pieces()).thenAnswer((_) async => pieces);
      final repository = CatalogRepositoryImpl(asset);
      expect(await repository.pieces(), Right<Failure, List<Piece>>(pieces));
      await repository.pieces();
      verify(asset.pieces()).called(1);
      when(asset.pieces()).thenThrow(const FormatException('broken'));
      expect(
        await CatalogRepositoryImpl(asset).pieces(),
        const Left<Failure, List<Piece>>(CacheFailure()),
      );
    });
  });

  test('keeps the pieces for the band, mixing the categories', () async {
    final asset = MockCatalogAssetDataSource();
    when(asset.pieces()).thenAnswer(
      (_) async => [
        _piece('top1', PieceCategory.top, {WarmthBand.mild}),
        _piece('top2', PieceCategory.top, {WarmthBand.mild, WarmthBand.cool}),
        _piece('top3', PieceCategory.top, {WarmthBand.hot}),
        _piece('coat', PieceCategory.outerwear, {WarmthBand.mild}),
        _piece('jeans', PieceCategory.bottom, {WarmthBand.mild}),
        _piece('dress', PieceCategory.dress, {WarmthBand.cool}),
      ],
    );
    final pieces = await GetPiecesForWeather(CatalogRepositoryImpl(asset))(
      WarmthBand.mild,
    );
    expect(pieces.getOrElse(() => []).map((piece) => piece.id), [
      'coat',
      'top1',
      'jeans',
      'top2',
    ]);
  });

  group('PicksLocalDataSourceImpl', () {
    test('remembers loved colourways, and forgets them', () async {
      final store = MemoryStore();
      final picks = PicksLocalDataSourceImpl(store);
      expect(picks.picks(), isEmpty);
      await picks.save({'a-1', 'b-2'});
      expect(PicksLocalDataSourceImpl(store).picks(), {'a-1', 'b-2'});
      await picks.save({'b-2'});
      expect(picks.picks(), {'b-2'});
      store.values['picks'] = 'not json';
      expect(picks.picks(), isEmpty);
    });

    test('remembers the picks last saved on one account only', () async {
      final store = MemoryStore();
      final picks = PicksLocalDataSourceImpl(store);
      expect(picks.synced('uid-1'), isEmpty);
      await picks.saveSynced('uid-1', {'a-1', 'b-2'});
      expect(PicksLocalDataSourceImpl(store).synced('uid-1'), {'a-1', 'b-2'});
      expect(picks.synced('uid-2'), isEmpty);
      store.values['picks_synced'] = 'not json';
      expect(picks.synced('uid-1'), isEmpty);
      await picks.saveSynced('uid-1', {'a-1'});
      await picks.forgetSynced();
      expect(picks.synced('uid-1'), isEmpty);
    });
  });

  test('adds many picks at once, keeping those already loved', () async {
    final repository = PicksRepositoryImpl(
      PicksLocalDataSourceImpl(MemoryStore()),
    );
    await repository.setPick('a-1', loved: true);
    expect((await repository.addPicks({'a-1', 'b-2'})).getOrElse(() => {}), {
      'a-1',
      'b-2',
    });
    expect((await repository.picks()).getOrElse(() => {}), {'a-1', 'b-2'});
  });

  test('unloves many picks at once, keeping the rest', () async {
    final repository = PicksRepositoryImpl(
      PicksLocalDataSourceImpl(MemoryStore()),
    );
    await repository.addPicks({'a-1', 'b-2', 'c-3'});
    expect(
      (await repository.removePicks({'a-1', 'c-3', 'x-9'})).getOrElse(() => {}),
      {'b-2'},
    );
    expect((await repository.picks()).getOrElse(() => {}), {'b-2'});
  });

  test('clearing forgets the picks and which ones an account holds', () async {
    final repository = PicksRepositoryImpl(
      PicksLocalDataSourceImpl(MemoryStore()),
    );
    await repository.setPick('a-1', loved: true);
    await repository.markSynced('uid-1', {'a-1'});
    await repository.clear();
    expect((await repository.picks()).getOrElse(() => {'x'}), isEmpty);
    expect((await repository.synced('uid-1')).getOrElse(() => {'x'}), isEmpty);
  });

  test('saves a pick and returns all of them', () async {
    final repository = PicksRepositoryImpl(
      PicksLocalDataSourceImpl(MemoryStore()),
    );
    Set<String> picked(Either<Failure, Set<String>> result) =>
        result.getOrElse(() => throw StateError('$result'));
    expect(picked(await repository.setPick('a-1', loved: true)), {'a-1'});
    expect(picked(await repository.setPick('b-1', loved: true)), {
      'a-1',
      'b-1',
    });
    expect(picked(await repository.setPick('a-1', loved: false)), {'b-1'});
    expect(picked(await repository.picks()), {'b-1'});
  });
}
