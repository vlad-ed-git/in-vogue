import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_prepare_data_source.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:in_vogue/features/photos/data/photo_format.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:path/path.dart' as p;

/// A 480 × 600 JPEG.
const _bodyJpeg = 'assets/images/example_body.jpg';

/// A [width] × [height] PNG in one colour, or in noise, which hardly
/// compresses.
Future<Uint8List> _png(int width, int height, {bool noise = false}) async {
  final ui.Image image;
  if (noise) {
    final random = Random(1);
    final pixels = Uint8List(width * height * 4);
    for (var i = 0; i < pixels.length; i++) {
      pixels[i] = i % 4 == 3 ? 255 : random.nextInt(256);
    }
    final decoded = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels,
      width,
      height,
      ui.PixelFormat.rgba8888,
      decoded.complete,
    );
    image = await decoded.future;
  } else {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawColor(const ui.Color(0xFF8C0F1F), ui.BlendMode.src);
    image = await recorder.endRecording().toImage(width, height);
  }
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

/// A [width] × [height] BMP in one colour: a format YouCam does not take.
Uint8List _bmp(int width, int height) {
  final row = (width * 3 + 3) & ~3;
  final size = 54 + row * height;
  final bytes = ByteData(size)
    ..setUint8(0, 0x42)
    ..setUint8(1, 0x4D)
    ..setUint32(2, size, Endian.little)
    ..setUint32(10, 54, Endian.little)
    ..setUint32(14, 40, Endian.little)
    ..setInt32(18, width, Endian.little)
    ..setInt32(22, height, Endian.little)
    ..setUint16(26, 1, Endian.little)
    ..setUint16(28, 24, Endian.little)
    ..setUint32(34, row * height, Endian.little);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < width; x++) {
      final at = 54 + y * row + x * 3;
      bytes
        ..setUint8(at, 0x1F)
        ..setUint8(at + 1, 0x0F)
        ..setUint8(at + 2, 0x8C);
    }
  }
  return bytes.buffer.asUint8List();
}

/// The photo's format and size.
Future<(PhotoFormat, int, int)> _read(String path) async {
  final format = PhotoFormat.of(File(path).readAsBytesSync());
  final buffer = await ui.ImmutableBuffer.fromFilePath(path);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final read = (format, descriptor.width, descriptor.height);
  descriptor.dispose();
  buffer.dispose();
  return read;
}

Matcher _refused(PhotoProblem problem) =>
    throwsA(isA<PhotoException>().having((e) => e.problem, 'problem', problem));

void main() {
  late Directory directory;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('chosen');
    addTearDown(() => directory.deleteSync(recursive: true));
  });

  String write(String name, List<int> bytes) =>
      (File(p.join(directory.path, name))..writeAsBytesSync(bytes)).path;

  testWidgets('uses a JPEG within the limits as it is', (tester) async {
    await tester.runAsync(() async {
      final path = write('photo.jpg', File(_bodyJpeg).readAsBytesSync());
      expect(
        await const PhotoPrepareDataSourceImpl().prepare(path, PhotoRole.body),
        ChosenPhoto(path: path),
      );
    });
  });

  testWidgets('names a photo for its format, whatever its name says', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final jpeg = File(_bodyJpeg).readAsBytesSync();
      final path = write('photo.heic', jpeg);
      final chosen = await const PhotoPrepareDataSourceImpl().prepare(
        path,
        PhotoRole.body,
      );
      expect(p.extension(chosen.path), '.jpg');
      expect(chosen.converted, isFalse);
      expect(File(chosen.path).readAsBytesSync(), jpeg);
    });
  });

  testWidgets('converts another format to PNG, and says so', (tester) async {
    await tester.runAsync(() async {
      final path = write('photo.bmp', _bmp(640, 480));
      final chosen = await const PhotoPrepareDataSourceImpl().prepare(
        path,
        PhotoRole.body,
      );
      expect(chosen.converted, isTrue);
      expect(p.extension(chosen.path), '.png');
      expect(await _read(chosen.path), (PhotoFormat.png, 640, 480));
    });
  });

  testWidgets('refuses a photo too small for its role', (tester) async {
    await tester.runAsync(() async {
      const prepare = PhotoPrepareDataSourceImpl();
      final body = write('body.png', await _png(500, 380));
      await expectLater(
        prepare.prepare(body, PhotoRole.body),
        _refused(PhotoProblem.tooSmall),
      );
      final face = write('face.png', await _png(319, 600));
      await expectLater(
        prepare.prepare(face, PhotoRole.face),
        _refused(PhotoProblem.tooSmall),
      );
      final small = write('small.bmp', _bmp(300, 200));
      await expectLater(
        prepare.prepare(small, PhotoRole.face),
        _refused(PhotoProblem.tooSmall),
      );
    });
  });

  testWidgets('cannot use what it cannot read', (tester) async {
    await tester.runAsync(() async {
      const prepare = PhotoPrepareDataSourceImpl();
      final broken = write('photo.jpg', [0xFF, 0xD8, 0xFF, 1, 2, 3]);
      await expectLater(
        prepare.prepare(broken, PhotoRole.body),
        _refused(PhotoProblem.unusable),
      );
      await expectLater(
        prepare.prepare(p.join(directory.path, 'none.jpg'), PhotoRole.body),
        _refused(PhotoProblem.unusable),
      );
    });
  });

  testWidgets('scales a photo over 4096 pixels down to 4096', (tester) async {
    await tester.runAsync(() async {
      final path = write('wide.png', await _png(4400, 500));
      final chosen = await const PhotoPrepareDataSourceImpl().prepare(
        path,
        PhotoRole.body,
      );
      expect(chosen.converted, isFalse);
      expect(await _read(chosen.path), (PhotoFormat.png, 4096, 465));
    });
  });

  testWidgets('scales a photo too heavy down until it fits', (tester) async {
    await tester.runAsync(() async {
      const limit = 1024 * 1024;
      final path = write('noise.png', await _png(1200, 900, noise: true));
      expect(File(path).lengthSync(), greaterThan(limit));
      final chosen = await const PhotoPrepareDataSourceImpl(
        maxBytes: limit,
      ).prepare(path, PhotoRole.face);
      expect(chosen.converted, isFalse);
      expect(File(chosen.path).lengthSync(), lessThan(limit));
      final (format, width, height) = await _read(chosen.path);
      expect(format, PhotoFormat.png);
      expect(width, lessThan(1200));
      expect(height, greaterThanOrEqualTo(320));
      expect(width / height, closeTo(4 / 3, 0.01));
    });
  });

  testWidgets('gives up when a photo only fits once too small', (tester) async {
    await tester.runAsync(() async {
      final path = write('noise.png', await _png(600, 450, noise: true));
      await expectLater(
        const PhotoPrepareDataSourceImpl(
          maxBytes: 50 * 1024,
        ).prepare(path, PhotoRole.body),
        _refused(PhotoProblem.unusable),
      );
    });
  });
}
