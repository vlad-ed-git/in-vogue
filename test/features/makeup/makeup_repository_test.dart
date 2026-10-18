import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/data/errors/log_messages_impl.dart';
import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/core/network/network_exceptions.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';
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
  late String face;
  final fingerprint = sha256.convert(const [1, 2, 3]).toString();
  final id = MakeupLookModel.idOf(fingerprint, 'coat+tee');

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('makeup');
    face = (File(
      '${directory.path}/face-1.jpg',
    )..writeAsBytesSync(const [1, 2, 3])).path;
    asset = MockMakeupAssetDataSource();
    remote = MockMakeupRemoteDataSource();
    pictures = LookPictureLocalDataSourceImpl(directory.path);
    repository = MakeupRepositoryImpl(
      assetDataSource: asset,
      remoteDataSource: remote,
      pictureDataSource: pictures,
      fingerprints: PhotoFingerprints(),
      logMessages: LogMessagesImpl(),
    );
  });

  tearDown(() => directory.delete(recursive: true));

  /// A look of coat+tee with its pictures in the phone's folder [folder].
  Future<MakeupLook> look([String? folder]) async {
    final before = await pictures.keep(
      'uid-1',
      folder ?? id,
      'before.png',
      _png,
    );
    final step = await pictures.keep('uid-1', folder ?? id, 'step-1.jpg', _jpg);
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
          title: LocalizedText('Brick-red lips'),
          howTo: LocalizedText('Line, then fill.'),
          products: const [LocalizedText('brick-red lipstick')],
          picture: step,
        ),
      ],
      matched: true,
    );
  }

  Future<MakeupLook?> read() async => (await repository.look(
    'uid-1',
    facePhoto: face,
    outfitSignature: 'coat+tee',
  )).getOrElse(() => throw StateError('look'));

  test("keeps a picture with its image type's extension, with the look of "
      'the face photo and outfit', () async {
    Future<String> keep(String name, List<int> picture) async =>
        (await repository.keepPicture(
          'uid-1',
          facePhoto: face,
          outfitSignature: 'coat+tee',
          name: name,
          picture: picture,
        )).getOrElse(() => '');
    final png = await keep('before', _png);
    final jpg = await keep('step-1', _jpg);
    expect(png, endsWith('/uid-1/$id/before.png'));
    expect(jpg, endsWith('/uid-1/$id/step-1.jpg'));
    expect(File(jpg).readAsBytesSync(), _jpg);
    Future<Either<Failure, String?>> kept(String fileName) =>
        repository.keptPicture(
          'uid-1',
          facePhoto: face,
          outfitSignature: 'coat+tee',
          fileName: fileName,
        );
    expect(await kept('step-1.jpg'), Right<Failure, String?>(jpg));
    expect(await kept('step-2.jpg'), const Right<Failure, String?>(null));
  });

  test('records a look: every picture to Storage, then its record on the '
      'account and the phone', () async {
    final made = await look();
    expect(
      await repository.record('uid-1', made, facePhoto: face),
      const Right<Failure, Unit>(unit),
    );
    verifyInOrder([
      remote.upload(
        'users/uid-1/makeup/$id/before.png',
        _png,
        contentType: 'image/png',
      ),
      remote.upload(
        'users/uid-1/makeup/$id/step-1.jpg',
        _jpg,
        contentType: 'image/jpeg',
      ),
      remote.writeLook('uid-1', id, {
        ...MakeupLookModel.toJson(made),
        'face': fingerprint,
      }),
    ]);
  });

  test('opens a look kept on the phone at once, without the account', () async {
    final made = await look();
    await repository.record('uid-1', made, facePhoto: face);
    expect(await read(), made);
    verifyNever(remote.look(any, any));
  });

  test('reads a look from the account with its pictures, fetching the '
      'missing ones, and keeps it on the phone', () async {
    final made = await look();
    when(remote.look('uid-1', id)).thenAnswer(
      (_) async => {...MakeupLookModel.toJson(made), 'face': fingerprint},
    );
    await File(made.steps.single.picture!).delete();
    when(
      remote.download('users/uid-1/makeup/$id/step-1.jpg'),
    ).thenAnswer((_) async => _jpg);
    final first = (await read())!;
    expect(first, made);
    expect(File(first.steps.single.picture!).readAsBytesSync(), _jpg);
    verifyNever(remote.download('users/uid-1/makeup/$id/before.png'));
    expect(await read(), made);
    verify(remote.look('uid-1', id)).called(1);
  });

  test('takes a look made before looks were kept by face photo for this '
      'face, never making it again', () async {
    final made = await look('coat+tee');
    when(remote.look('uid-1', id)).thenAnswer((_) async => null);
    when(
      remote.look('uid-1', 'coat+tee'),
    ).thenAnswer((_) async => MakeupLookModel.toJson(made));
    expect(await read(), made);
    verify(remote.setLookFace('uid-1', 'coat+tee', fingerprint)).called(1);
    expect(await read(), made);
    verify(remote.look('uid-1', 'coat+tee')).called(1);
  });

  test("a look made on another face photo isn't this one's", () async {
    final made = await look('coat+tee');
    when(remote.look('uid-1', id)).thenAnswer((_) async => null);
    when(remote.look('uid-1', 'coat+tee')).thenAnswer(
      (_) async => {...MakeupLookModel.toJson(made), 'face': 'another'},
    );
    expect(await read(), isNull);
    verifyNever(remote.setLookFace(any, any, any));
  });

  test('has no look for an outfit without one', () async {
    when(remote.look(any, any)).thenAnswer((_) async => null);
    expect(
      await repository.look('uid-1', facePhoto: face, outfitSignature: 'dress'),
      const Right<Failure, MakeupLook?>(null),
    );
  });

  test('reads the latest look, named by its record or, made before looks '
      'were kept by face photo, by its id', () async {
    final made = await look();
    when(remote.latestLook('uid-1')).thenAnswer(
      (_) async => (id, {...MakeupLookModel.toJson(made), 'face': fingerprint}),
    );
    expect((await repository.latestLook('uid-1')).getOrElse(() => null), made);
    final legacy = await look('coat+tee');
    final json = MakeupLookModel.toJson(legacy)..remove('signature');
    when(
      remote.latestLook('uid-1'),
    ).thenAnswer((_) async => ('coat+tee', json));
    expect(
      (await repository.latestLook('uid-1')).getOrElse(() => null),
      legacy,
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
