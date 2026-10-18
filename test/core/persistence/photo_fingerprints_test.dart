import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/persistence/cache_exception.dart';
import 'package:in_vogue/core/persistence/photo_fingerprints.dart';

void main() {
  test("a photo's fingerprint is the SHA-256 of its bytes, read once for "
      'each file', () async {
    var reads = 0;
    final fingerprints = PhotoFingerprints(
      read: (path) async {
        reads++;
        return utf8.encode('bytes of $path');
      },
    );
    final first = await fingerprints.of('/photos/body-1.jpg');
    expect(
      first,
      sha256.convert(utf8.encode('bytes of /photos/body-1.jpg')).toString(),
    );
    expect(await fingerprints.of('/photos/body-1.jpg'), first);
    expect(reads, 1);
    expect(await fingerprints.of('/photos/body-2.jpg'), isNot(first));
  });

  test("a photo that can't be read is read again next time", () async {
    var missing = true;
    final fingerprints = PhotoFingerprints(
      read: (path) async {
        if (missing) throw const FileSystemException('gone');
        return [1, 2, 3];
      },
    );
    await expectLater(
      fingerprints.of('/photos/face-1.jpg'),
      throwsA(isA<CacheException>()),
    );
    missing = false;
    expect(
      await fingerprints.of('/photos/face-1.jpg'),
      sha256.convert([1, 2, 3]).toString(),
    );
  });

  test('reads the photo file itself by default', () async {
    final folder = Directory.systemTemp.createTempSync('fingerprints_');
    addTearDown(() => folder.deleteSync(recursive: true));
    final photo = File('${folder.path}/body-1.jpg')
      ..writeAsBytesSync([0xFF, 0xD8, 0xFF]);
    expect(
      await PhotoFingerprints().of(photo.path),
      sha256.convert([0xFF, 0xD8, 0xFF]).toString(),
    );
  });
}
