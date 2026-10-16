import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_asset_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_picture_local_data_source.dart';
import 'package:in_vogue/features/outfits/data/data_sources/outfit_remote_data_source.dart';
import 'package:in_vogue/features/outfits/data/models/outfit_record_model.dart';
import 'package:in_vogue/features/outfits/data/repositories/outfit_repository_impl.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
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
final _day = DateTime.utc(2026, 10, 17);

OutfitRecord _record({
  String signature = 'jeans+tee',
  String outfitId = 'o1',
  Occasion occasion = Occasion.casual,
  DateTime? createdAt,
}) => (
  signature: signature,
  outfitId: outfitId,
  pieces: const ['everlane:jeans', 'everlane:tee'],
  cell: 'mild|dry|calm|casual',
  date: _day,
  occasion: occasion,
  imagePath: 'users/uid-1/outfits/$signature.jpg',
  createdAt: createdAt,
);

@GenerateMocks([
  OutfitAssetDataSource,
  OutfitRemoteDataSource,
  OutfitPictureLocalDataSource,
])
void main() {
  late MockOutfitAssetDataSource asset;
  late MockOutfitRemoteDataSource remote;
  late MockOutfitPictureLocalDataSource pictures;
  late OutfitRepositoryImpl repository;

  setUp(() {
    asset = MockOutfitAssetDataSource();
    remote = MockOutfitRemoteDataSource();
    pictures = MockOutfitPictureLocalDataSource();
    repository = OutfitRepositoryImpl(
      assetDataSource: asset,
      remoteDataSource: remote,
      pictureDataSource: pictures,
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
    when(pictures.keep(any, any, any)).thenAnswer(
      (invocation) async =>
          '/support/outfits/uid-1/${invocation.positionalArguments[1]}',
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

  test("finds the day's outfit with its picture on the phone", () async {
    when(remote.recordsFor('uid-1', '2026-10-17')).thenAnswer(
      (_) async => [
        _record(createdAt: DateTime.utc(2026, 10, 16, 9)),
        _record(
          signature: 'dress',
          outfitId: 'o2',
          occasion: Occasion.goingOut,
        ),
      ],
    );
    when(
      pictures.kept('uid-1', 'jeans+tee.jpg'),
    ).thenReturn('/support/outfits/uid-1/jeans+tee.jpg');
    final found = await repository.dayOutfit(
      'uid-1',
      date: _day,
      occasion: Occasion.casual,
    );
    expect(
      found,
      Right<Failure, DayOutfit?>(
        DayOutfit(
          outfit: _tee,
          date: _day,
          occasion: Occasion.casual,
          cell: 'mild|dry|calm|casual',
          picture: '/support/outfits/uid-1/jeans+tee.jpg',
        ),
      ),
    );
    verifyNever(remote.download(any));
  });

  test('downloads the picture once when the phone has none', () async {
    when(
      remote.recordsFor(any, any),
    ).thenAnswer((_) async => [_record(createdAt: DateTime.utc(2026, 10, 16))]);
    when(pictures.kept(any, any)).thenReturn(null);
    when(remote.download(any)).thenAnswer((_) async => const [0xFF, 0xD8]);
    final found = (await repository.dayOutfit(
      'uid-1',
      date: _day,
      occasion: Occasion.casual,
    )).getOrElse(() => null);
    expect(found?.picture, '/support/outfits/uid-1/jeans+tee.jpg');
    verify(remote.download('users/uid-1/outfits/jeans+tee.jpg')).called(1);
    verify(
      pictures.keep('uid-1', 'jeans+tee.jpg', const [0xFF, 0xD8]),
    ).called(1);
  });

  test('takes the latest outfit made for the occasion', () async {
    when(remote.recordsFor(any, any)).thenAnswer(
      (_) async => [
        _record(signature: 'old', createdAt: DateTime.utc(2026, 10, 16, 8)),
        _record(createdAt: DateTime.utc(2026, 10, 16, 9)),
      ],
    );
    when(
      pictures.kept(any, any),
    ).thenAnswer((invocation) => '/kept/${invocation.positionalArguments[1]}');
    final found = (await repository.dayOutfit(
      'uid-1',
      date: _day,
      occasion: Occasion.casual,
    )).getOrElse(() => null);
    expect(found?.picture, '/kept/jeans+tee.jpg');
  });

  test('has no outfit for a day none was made for', () async {
    when(remote.recordsFor(any, any)).thenAnswer((_) async => []);
    expect(
      await repository.dayOutfit(
        'uid-1',
        date: _day,
        occasion: Occasion.casual,
      ),
      const Right<Failure, DayOutfit?>(null),
    );
  });

  test('keeps the picture, uploads it, then records the outfit', () async {
    when(
      remote.upload(any, any, contentType: anyNamed('contentType')),
    ).thenAnswer((_) async {});
    when(remote.write(any, any)).thenAnswer((_) async {});
    final made = await repository.record(
      'uid-1',
      outfit: _tee,
      cell: 'mild|dry|calm|casual',
      date: _day,
      occasion: Occasion.casual,
      picture: const [0x89, 0x50, 0x4E, 0x47],
    );
    expect(
      made.getOrElse(() => throw StateError('made')).picture,
      '/support/outfits/uid-1/jeans+tee.png',
    );
    final verified = verifyInOrder([
      pictures.keep('uid-1', 'jeans+tee.png', const [0x89, 0x50, 0x4E, 0x47]),
      remote.upload('users/uid-1/outfits/jeans+tee.png', const [
        0x89,
        0x50,
        0x4E,
        0x47,
      ], contentType: 'image/png'),
      remote.write('uid-1', captureAny),
    ]);
    final written = verified.last.captured.single as OutfitRecord;
    expect(written.signature, 'jeans+tee');
    expect(written.outfitId, 'o1');
    expect(written.pieces, _tee.pieces);
    expect(written.imagePath, 'users/uid-1/outfits/jeans+tee.png');
  });

  test('says when the account cannot be reached', () async {
    when(
      remote.signatures(any),
    ).thenThrow(NetworkException(Exception(), StackTrace.current));
    expect(
      await repository.shownSignatures('uid-1'),
      const Left<Failure, Set<String>>(NetworkFailure()),
    );
  });
}
