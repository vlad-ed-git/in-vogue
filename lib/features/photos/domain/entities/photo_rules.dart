import 'dart:math' as math;

import 'package:in_vogue/features/photos/domain/entities/photo_role.dart';

/// What YouCam takes: a photo under 10 MB, at most 4096 pixels a side,
/// and large enough for its role.
abstract final class PhotoRules {
  /// Bytes a photo stays under.
  static const maxBytes = 10 * 1024 * 1024;

  /// Pixels on a photo's longest side, at most.
  static const maxSide = 4096;

  /// Whether a [width] × [height] photo is large enough for [role]: AI
  /// Clothes lists 512 × 384, either way round, for the body; the skin
  /// analysis needs 320 pixels a side for the face.
  static bool largeEnough(PhotoRole role, int width, int height) {
    final long = math.max(width, height);
    final short = math.min(width, height);
    return switch (role) {
      PhotoRole.body => long >= 512 && short >= 384,
      PhotoRole.face => short >= 320,
    };
  }

  /// Whether a [width] × [height] photo of [bytes] is within the limits.
  static bool fits(int width, int height, int bytes) =>
      math.max(width, height) <= maxSide && bytes < maxBytes;
}
