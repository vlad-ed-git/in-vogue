import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/photos/data/photo_format.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_rules.dart';

void main() {
  group('PhotoRules', () {
    test('a body photo needs 512 × 384, either way round', () {
      expect(PhotoRules.largeEnough(PhotoRole.body, 512, 384), isTrue);
      expect(PhotoRules.largeEnough(PhotoRole.body, 384, 512), isTrue);
      expect(PhotoRules.largeEnough(PhotoRole.body, 480, 600), isTrue);
      expect(PhotoRules.largeEnough(PhotoRole.body, 511, 400), isFalse);
      expect(PhotoRules.largeEnough(PhotoRole.body, 383, 2000), isFalse);
    });

    test('a face photo needs 320 pixels a side', () {
      expect(PhotoRules.largeEnough(PhotoRole.face, 320, 320), isTrue);
      expect(PhotoRules.largeEnough(PhotoRole.face, 319, 1000), isFalse);
    });

    test('a photo fits at 4096 pixels a side and under 10 MB', () {
      const tenMegabytes = 10 * 1024 * 1024;
      expect(PhotoRules.fits(4096, 3072, tenMegabytes - 1), isTrue);
      expect(PhotoRules.fits(3072, 4097, 1000), isFalse);
      expect(PhotoRules.fits(2048, 1536, tenMegabytes), isFalse);
    });
  });

  group('PhotoFormat', () {
    test('tells JPEG and PNG by their first bytes', () {
      expect(
        PhotoFormat.of([0xFF, 0xD8, 0xFF, 0xE0, 0, 0x10]),
        PhotoFormat.jpeg,
      );
      expect(
        PhotoFormat.of([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        PhotoFormat.png,
      );
      expect(PhotoFormat.jpeg.extension, 'jpg');
      expect(PhotoFormat.png.extension, 'png');
    });

    test('takes every other format as one to convert', () {
      for (final header in [
        'GIF89a'.codeUnits,
        [...'RIFF'.codeUnits, 0, 0, 0, 0, ...'WEBP'.codeUnits],
        [0, 0, 0, 0x18, ...'ftypheic'.codeUnits],
        'BM'.codeUnits,
        [0x89, 0x50, 0x4E, 0x47],
        <int>[],
      ]) {
        expect(PhotoFormat.of(header), PhotoFormat.other, reason: '$header');
      }
    });
  });
}
