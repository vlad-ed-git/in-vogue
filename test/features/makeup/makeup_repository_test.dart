import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/features/makeup/data/data_sources/look_picture_local_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_asset_data_source.dart';
import 'package:in_vogue/features/makeup/data/data_sources/makeup_remote_data_source.dart';
import 'package:in_vogue/features/makeup/data/models/makeup_look_model.dart';
import 'package:in_vogue/features/makeup/data/repositories/makeup_repository_impl.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/makeup/domain/entities/skin_profile.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'makeup_repository_test.mocks.dart';

const _png = [0x89, 0x50, 0x4E, 0x47, 1];
const _jpg = [0xFF, 0xD8, 0xFF, 2];

@GenerateMocks([MakeupAssetDataSource, MakeupRemoteDataSource])
void main() {
  late Directory directory;
  late MockMakeupAssetDataSource asset;
  late MockMakeupRemoteDataSource remote;
  late LookPictureLocalDataSourceImpl pictures;
  late MakeupRepositoryImpl repository;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('makeup');
    asset = MockMakeupAssetDataSource();
    remote = MockMakeupRemoteDataSource();
    pictures = LookPictureLocalDataSourceImpl(directory.path);
    repository = MakeupRepositoryImpl(
      assetDataSource: asset,
      remoteDataSource: remote,
      pictureDataSource: pictures,
      logMessages: LogMessagesImpl(),
    );
  });

  tearDown(() => directory.delete(recursive: true));

  Future<MakeupLook> look() async {
    final before = await pictures.keep('uid-1', 'coat+tee', 'before.png', _png);
    final step = await pictures.keep('uid-1', 'coat+tee', 'step-1.jpg', _jpg);
    return MakeupLook(
      outfitSignature: 'coat+tee',
      date: DateTime.utc(2026, 10, 17),
      occasion: Occasion.goingOut,
      palette: OutfitPalette.warmNeutral,
      cheeks: CheekColour.terracotta,
      lips: LipColour.brick,
      before: before,
      steps: [
        LookStep(
          title: 'Brick-red lips',
          howTo: 'Line, then fill.',
          products: const ['brick-red lipstick'],
          picture: step,
        ),
      ],
      matched: true,
    );
  }

  test("keeps a picture with its image type's extension", () async {
    final png = (await repository.keepPicture(
      'uid-1',
      'coat+tee',
      'before',
      _png,
    )).getOrElse(() => '');
    final jpg = (await repository.keepPicture(
      'uid-1',
      'coat+tee',
      'step-1',
      _jpg,
    )).getOrElse(() => '');
    expect(png, endsWith('/uid-1/coat+tee/before.png'));
    expect(jpg, endsWith('/uid-1/coat+tee/step-1.jpg'));
    expect(File(jpg).readAsBytesSync(), _jpg);
    expect(
      await repository.keptPicture('uid-1', 'coat+tee', 'step-1.jpg'),
      Right<Failure, String?>(jpg),
    );
    expect(
      await repository.keptPicture('uid-1', 'coat+tee', 'step-2.jpg'),
      const Right<Failure, String?>(null),
    );
  });

  test('records a look: every picture to Storage, then its record', () async {
    final made = await look();
    expect(
      await repository.record('uid-1', made),
      const Right<Failure, Unit>(unit),
    );
    verifyInOrder([
      remote.upload(
        'users/uid-1/makeup/coat+tee/before.png',
        _png,
        contentType: 'image/png',
      ),
      remote.upload(
        'users/uid-1/makeup/coat+tee/step-1.jpg',
        _jpg,
        contentType: 'image/jpeg',
      ),
      remote.writeLook('uid-1', 'coat+tee', MakeupLookModel.toJson(made)),
    ]);
  });

  test('reads a look with its pictures, fetching the missing ones', () async {
    final made = await look();
    when(
      remote.look('uid-1', 'coat+tee'),
    ).thenAnswer((_) async => MakeupLookModel.toJson(made));
    await File(made.steps.single.picture!).delete();
    when(
      remote.download('users/uid-1/makeup/coat+tee/step-1.jpg'),
    ).thenAnswer((_) async => _jpg);
    final read = (await repository.look(
      'uid-1',
      'coat+tee',
    )).getOrElse(() => null)!;
    expect(read, made);
    expect(File(read.steps.single.picture!).readAsBytesSync(), _jpg);
    verifyNever(remote.download('users/uid-1/makeup/coat+tee/before.png'));
  });

  test('has no look for an outfit without one', () async {
    when(remote.look(any, any)).thenAnswer((_) async => null);
    expect(
      await repository.look('uid-1', 'dress'),
      const Right<Failure, MakeupLook?>(null),
    );
  });

  test("keeps a face photo's colours under its SHA-256", () async {
    final photo = File('${directory.path}/face-1.jpg')
      ..writeAsBytesSync(const [1, 2, 3]);
    final id = sha256.convert(const [1, 2, 3]).toString();
    when(remote.colours('uid-1', id)).thenAnswer(
      (_) async => {
        'skin': '#E8C4AE',
        'eyebrow': '#3B2A22',
        'lip': '#C98276',
        'hair': '#42280E',
        'clear': true,
      },
    );
    expect(
      (await repository.faceColours('uid-1', photo.path)).getOrElse(() => null),
      const FaceColours(
        skin: '#E8C4AE',
        eyebrow: '#3B2A22',
        lip: '#C98276',
        hair: '#42280E',
        clear: true,
      ),
    );
  });

  test('reads the bundled recipes once', () async {
    when(asset.recipes()).thenAnswer(
      (_) async => {
        'work|x': const MakeupRecipe(
          key: 'work|x',
          cheeks: CheekColour.peach,
          lips: LipColour.nude,
          steps: [],
        ),
      },
    );
    expect(
      (await repository.recipe('work|x')).getOrElse(() => null)?.key,
      'work|x',
    );
    expect((await repository.recipe('work|y')).getOrElse(() => null), isNull);
    verify(asset.recipes()).called(1);
  });

  test('says offline when the account cannot be reached', () async {
    when(
      remote.latestLook(any),
    ).thenThrow(NetworkException(Exception(), StackTrace.current));
    expect(
      await repository.latestLook('uid-1'),
      const Left<Failure, MakeupLook?>(NetworkFailure()),
    );
  });
}
