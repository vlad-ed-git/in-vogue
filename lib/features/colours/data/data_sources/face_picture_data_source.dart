import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:in_vogue/features/photos/data/photo_exception.dart';

abstract interface class FacePictureDataSource {
  /// The photo at [path], upright and at most [FacePictureDataSourceImpl
  /// .maxSide] pixels a side, as a PNG. Throws [PhotoException] when it
  /// cannot be read.
  Future<List<int>> prepare(String path);
}

/// Decodes a face photo with the engine, which turns it upright, and
/// encodes a smaller copy as a PNG.
class FacePictureDataSourceImpl implements FacePictureDataSource {
  const FacePictureDataSourceImpl();

  /// Longest side, in pixels: the analysis reads images up to 1080 pixels
  /// and needs at least 320.
  static const maxSide = 1024;

  /// The size [width] × [height] scales to so its longest side is at most
  /// [maxSide].
  static ui.TargetImageSize fitted(int width, int height) {
    final scale = math.min(1, maxSide / math.max(width, height));
    return ui.TargetImageSize(
      width: math.max(1, (width * scale).round()),
      height: math.max(1, (height * scale).round()),
    );
  }

  @override
  Future<List<int>> prepare(String path) async {
    final ui.Image image;
    try {
      final buffer = await ui.ImmutableBuffer.fromFilePath(path);
      final codec = await ui.instantiateImageCodecWithSize(
        buffer,
        getTargetSize: fitted,
      );
      image = (await codec.getNextFrame()).image;
      codec.dispose();
    } on Exception catch (error, stack) {
      throw PhotoException(error, stack);
    }
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw PhotoException(StateError('No PNG'), StackTrace.current);
      }
      return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    } finally {
      image.dispose();
    }
  }
}
