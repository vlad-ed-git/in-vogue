import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/repositories/makeup_repository.dart';
import 'package:in_vogue/features/makeup/domain/usecases/get_makeup_look.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/user_photo.dart';
import 'package:in_vogue/features/photos/domain/repositories/photo_repository.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'get_makeup_look_test.mocks.dart';

const _face = UserPhoto(
  role: PhotoRole.face,
  path: '/support/photos/face-1.jpg',
  revision: 1,
);
const _params = MakeupLookParams(
  accountId: 'uid-1',
  outfitSignature: 'coat+tee',
);

@GenerateMocks([MakeupRepository, PhotoRepository])
void main() {
  late MockMakeupRepository looks;
  late MockPhotoRepository photos;

  setUp(() {
    looks = MockMakeupRepository();
    photos = MockPhotoRepository();
  });

  test("reads the outfit's look made on the face photo", () async {
    when(
      photos.kept(PhotoRole.face),
    ).thenAnswer((_) async => const Right(_face));
    when(
      looks.look('uid-1', facePhoto: _face.path, outfitSignature: 'coat+tee'),
    ).thenAnswer((_) async => const Right(null));
    expect(
      await GetMakeupLook(looks, photos)(_params),
      const Right<Failure, MakeupLook?>(null),
    );
    verify(
      looks.look('uid-1', facePhoto: _face.path, outfitSignature: 'coat+tee'),
    ).called(1);
  });

  test('has no look without a face photo', () async {
    when(
      photos.kept(PhotoRole.face),
    ).thenAnswer((_) async => const Right(null));
    expect(
      await GetMakeupLook(looks, photos)(_params),
      const Right<Failure, MakeupLook?>(null),
    );
    verifyZeroInteractions(looks);
  });
}
