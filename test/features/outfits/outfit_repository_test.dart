import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/repositories/outfit_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'outfit_repository_test.mocks.dart';

const _tee = Outfit(
  id: 'o1',
  signature: 'jeans+tee',
  pieces: ['everlane:jeans', 'everlane:tee'],
  passes: [],
  reasons: {'mild|dry|calm|casual': 'A tee with jeans for a mild day off.'},
);

@GenerateMocks([OutfitAssetDataSource])
void main() {
  late MockOutfitAssetDataSource asset;
  late OutfitRepositoryImpl repository;

  setUp(() {
    asset = MockOutfitAssetDataSource();
    repository = OutfitRepositoryImpl(
      assetDataSource: asset,
      logMessages: LogMessagesImpl(),
    );
    when(asset.index()).thenAnswer(
      (_) async => (
        cells: {
          'mild|dry|calm|casual': ['o1', 'missing'],
        },
        outfits: {'o1': _tee},
      ),
    );
  });

  test("lists a cell's outfits in order and reads the asset once", () async {
    expect(
      (await repository.outfitsFor('mild|dry|calm|casual')).getOrElse(() => []),
      [_tee],
    );
    expect((await repository.outfit('o1')).getOrElse(() => null), _tee);
    verify(asset.index()).called(1);
  });

  test('has no outfits for a cell the asset lacks', () async {
    expect(
      (await repository.outfitsFor('hot|snow|calm|work')).getOrElse(
        () => [_tee],
      ),
      isEmpty,
    );
    expect((await repository.outfit('o9')).getOrElse(() => _tee), isNull);
  });

  test('says when the asset cannot be read, and reads it again', () async {
    when(
      asset.index(),
    ).thenAnswer((_) => Future.error(const FormatException('Not outfits')));
    expect(
      await repository.outfitsFor('mild|dry|calm|casual'),
      const Left<Failure, List<Outfit>>(CacheFailure()),
    );
    when(asset.index()).thenAnswer(
      (_) async => (
        cells: {
          'mild|dry|calm|casual': ['o1'],
        },
        outfits: {'o1': _tee},
      ),
    );
    expect(
      (await repository.outfitsFor('mild|dry|calm|casual')).getOrElse(() => []),
      [_tee],
    );
  });
}
