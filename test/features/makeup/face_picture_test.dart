import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/makeup/data/data_sources/face_picture_data_source.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';

/// A [width] × [height] PNG.
Future<List<int>> _png(int width, int height) async {
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..color = const ui.Color(0xFFC69C82),
  );
  final image = await recorder.endRecording().toImage(width, height);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

Future<ui.Image> _decode(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(
    bytes is Uint8List ? bytes : Uint8List.fromList(bytes),
  );
  return (await codec.getNextFrame()).image;
}

void main() {
  test('scales a photo down to 1024 pixels on its longest side', () {
    ui.TargetImageSize size(int width, int height) =>
        FacePictureDataSourceImpl.fitted(width, height);
    expect(size(2048, 1536).width, 1024);
    expect(size(2048, 1536).height, 768);
    expect(size(1000, 4000).width, 256);
    expect(size(1000, 4000).height, 1024);
    expect(size(800, 600).width, 800);
    expect(size(800, 600).height, 600);
  });

  testWidgets('copies a face photo as a smaller PNG', (tester) async {
    final directory = Directory.systemTemp.createTempSync('faces');
    addTearDown(() => directory.deleteSync(recursive: true));
    await tester.runAsync(() async {
      final photo = File('${directory.path}/face-1.png')
        ..writeAsBytesSync(await _png(2000, 1000));
      final prepared = await const FacePictureDataSourceImpl().prepare(
        photo.path,
      );
      expect(prepared.take(4), [0x89, 0x50, 0x4E, 0x47]);
      final image = await _decode(prepared);
      expect((image.width, image.height), (1024, 512));
      image.dispose();
    });
  });

  testWidgets('cannot copy what is not a photo', (tester) async {
    final directory = Directory.systemTemp.createTempSync('faces');
    addTearDown(() => directory.deleteSync(recursive: true));
    await tester.runAsync(() async {
      final file = File('${directory.path}/face-1.jpg')
        ..writeAsBytesSync(const [1, 2, 3]);
      await expectLater(
        const FacePictureDataSourceImpl().prepare(file.path),
        throwsA(isA<PhotoException>()),
      );
      await expectLater(
        const FacePictureDataSourceImpl().prepare('${directory.path}/none.jpg'),
        throwsA(isA<PhotoException>()),
      );
    });
  });
}
