import 'package:equatable/equatable.dart';

/// How deep the skin is, in the knowledge base's three shade groups.
enum ShadeGroup { light, medium, deep }

/// How far the hair and brows are from the skin in lightness.
enum SkinContrast { low, medium, high }

/// The colours the skin-tone analysis sampled from a face photo, as
/// `#RRGGBB`.
class FaceColours extends Equatable {
  const FaceColours({
    required this.skin,
    required this.eyebrow,
    required this.lip,
    required this.hair,
    required this.clear,
  });

  final String skin;
  final String eyebrow;
  final String lip;
  final String hair;

  /// Whether the photo was clear enough for the colours to be trusted:
  /// one face, frontal, well lit, facing the camera.
  final bool clear;

  @override
  List<Object?> get props => [skin, eyebrow, lip, hair, clear];
}

/// What makeup is matched to: the skin's shade group and contrast, and the
/// colours the steps put on the face, as `#RRGGBB`.
class SkinProfile extends Equatable {
  const SkinProfile({
    required this.shadeGroup,
    required this.contrast,
    required this.foundation,
    required this.concealer,
    required this.brow,
    required this.nudeLip,
    required this.matched,
  });

  final ShadeGroup shadeGroup;
  final SkinContrast contrast;
  final String foundation;
  final String concealer;
  final String brow;
  final String nudeLip;

  /// Whether the profile comes from the person's own colours rather than
  /// neutral ones.
  final bool matched;

  @override
  List<Object?> get props => [
    shadeGroup,
    contrast,
    foundation,
    concealer,
    brow,
    nudeLip,
    matched,
  ];
}
