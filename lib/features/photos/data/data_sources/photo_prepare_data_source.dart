import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/photos/data/photo_exception.dart';
import 'package:in_vogue/features/photos/data/photo_format.dart';
import 'package:in_vogue/features/photos/domain/entities/chosen_photo.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';
import 'package:in_vogue/features/photos/domain/entities/photo_rules.dart';
import 'package:path/path.dart' as p;

abstract interface class PhotoPrepareDataSource {
  /// The photo at [path] made ready for YouCam as a [role] photo: a JPEG
  /// or PNG file named for its format, within [PhotoRules]. Throws
  /// [PhotoException] when it is too small, or cannot be read or
  /// converted.
  Future<ChosenPhoto> prepare(String path, PhotoRole role);
}

/// Reads photos with the engine's codecs, which turn them upright. A JPEG
/// or PNG within the limits is used as it is; any other format is
/// converted to PNG, and a photo too large is scaled down until it fits.
class PhotoPrepareDataSourceImpl implements PhotoPrepareDataSource {
  const PhotoPrepareDataSourceImpl({this.maxBytes = PhotoRules.maxBytes});

  /// Bytes a prepared photo stays under.
  final int maxBytes;

  /// Times a photo is scaled down to fit before it is given up.
  static const attempts = 5;

  @override
  Future<ChosenPhoto> prepare(String path, PhotoRole role) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    try {
      final file = File(path);
      final format = PhotoFormat.of(await _header(file));
      buffer = await ui.ImmutableBuffer.fromFilePath(path);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      if (!PhotoRules.largeEnough(role, width, height)) {
        throw PhotoException(
          StateError('$width × $height'),
          StackTrace.current,
          PhotoProblem.tooSmall,
        );
      }
      final bytes = await file.length();
      if (format.extension case final extension?
          when PhotoRules.fits(width, height, bytes, byteLimit: maxBytes)) {
        return ChosenPhoto(path: await _named(file, extension));
      }
      return ChosenPhoto(
        path: await _png(descriptor, path, role),
        converted: format == PhotoFormat.other,
      );
    } on PhotoException {
      rethrow;
    } on Exception catch (error, stack) {
      throw PhotoException(error, stack, PhotoProblem.unusable);
    } finally {
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  /// [descriptor]'s photo as a PNG beside [path], scaled down until it is
  /// within the limits and still large enough for [role].
  Future<String> _png(
    ui.ImageDescriptor descriptor,
    String path,
    PhotoRole role,
  ) async {
    final width = descriptor.width;
    final height = descriptor.height;
    var scale = math.min(1.0, PhotoRules.maxSide / math.max(width, height));
    for (var attempt = 0; attempt < attempts; attempt++) {
      final scaledWidth = math.max(1, (width * scale).round());
      final scaledHeight = math.max(1, (height * scale).round());
      if (!PhotoRules.largeEnough(role, scaledWidth, scaledHeight)) break;
      final png = await _encode(descriptor, scaledWidth, scaledHeight);
      if (png.length < maxBytes) {
        final file = File(_beside(path, 'png'));
        await file.writeAsBytes(png, flush: true);
        return file.path;
      }
      // Its bytes follow its area: shrink it to fit, with room to spare.
      scale *= math.sqrt(maxBytes / png.length) * 0.9;
    }
    throw PhotoException(
      StateError('No size fits'),
      StackTrace.current,
      PhotoProblem.unusable,
    );
  }

  static Future<Uint8List> _encode(
    ui.ImageDescriptor descriptor,
    int width,
    int height,
  ) async {
    final codec = await descriptor.instantiateCodec(
      targetWidth: width,
      targetHeight: height,
    );
    final ui.Image image;
    try {
      image = (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
    try {
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) {
        throw PhotoException(
          StateError('No PNG'),
          StackTrace.current,
          PhotoProblem.unusable,
        );
      }
      return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
    } finally {
      image.dispose();
    }
  }

  static Future<List<int>> _header(File file) async {
    final opened = await file.open();
    try {
      return await opened.read(PhotoFormat.headerLength);
    } finally {
      await opened.close();
    }
  }

  /// [file] itself when its name ends in [extension], or a copy that does.
  static Future<String> _named(File file, String extension) async {
    final current = p.extension(file.path).toLowerCase();
    if (current == '.$extension' ||
        (extension == 'jpg' && current == '.jpeg')) {
      return file.path;
    }
    return (await file.copy(_beside(file.path, extension))).path;
  }

  /// A new file beside [path], with [extension].
  static String _beside(String path, String extension) => p.join(
    p.dirname(path),
    '${p.basenameWithoutExtension(path)}-ready.$extension',
  );
}
