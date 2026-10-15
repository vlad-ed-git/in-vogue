import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/features/photos/data/data_sources/photo_check_data_source.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the phone tells a head-to-toe photo from a cropped one', (
    tester,
  ) async {
    final folder = await Directory.systemTemp.createTemp('photo_check_');
    addTearDown(() => folder.delete(recursive: true));
    final example = (await rootBundle.load(
      'assets/images/example_body.jpg',
    )).buffer.asUint8List();
    final whole = File('${folder.path}/whole.jpg')..writeAsBytesSync(example);
    final top = File('${folder.path}/top.png')
      ..writeAsBytesSync(await _topHalf(example));

    final check = PhotoCheckDataSourceImpl();
    expect(await check.isFullLength(whole.path), isTrue);
    expect(await check.isFullLength(top.path), isFalse);
  });
}

/// The top half of the [encoded] image, as a PNG.
Future<Uint8List> _topHalf(Uint8List encoded) async {
  final frame = await (await ui.instantiateImageCodec(encoded)).getNextFrame();
  final image = frame.image;
  final half = ui.Rect.fromLTWH(
    0,
    0,
    image.width.toDouble(),
    (image.height ~/ 2).toDouble(),
  );
  final recorder = ui.PictureRecorder();
  ui.Canvas(recorder).drawImageRect(image, half, half, ui.Paint());
  final cropped = await recorder.endRecording().toImage(
    image.width,
    image.height ~/ 2,
  );
  final png = await cropped.toByteData(format: ui.ImageByteFormat.png);
  return png!.buffer.asUint8List();
}
