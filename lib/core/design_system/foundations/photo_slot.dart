import 'package:flutter/material.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';

/// A photograph in a square-cut frame: tiles, pickers, Shop items, faces.
///
/// While the photo is missing or loading, the frame is a plain Rose block at
/// its final size: no shimmer, no spinner, no percentage. Photos fill their
/// frame ([BoxFit.cover]); the user's full-length portrait uses `PhotoStage`,
/// which contains instead.
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({
    this.image,
    this.aspectRatio = InVogueLayout.portraitAspectRatio,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.opacity = 1,
    this.background = InVogueColors.accent,
    this.semanticLabel,
    this.overlay,
    super.key,
  });

  final ImageProvider? image;

  /// Width over height; 4:5 unless the frame says otherwise.
  final double aspectRatio;
  final BoxFit fit;
  final Alignment alignment;

  /// [InVogueLayout.opacityLocked] behind Go Pro.
  final double opacity;

  /// The empty and loading fill: Rose, or paper where a partner photo is
  /// contained.
  final Color background;

  /// What the photo shows; null for a decorative photo.
  final String? semanticLabel;

  /// Drawn over the photo: only a check badge or a lock, never words.
  final Widget? overlay;

  @override
  Widget build(BuildContext context) {
    Widget? photo;
    if (image != null) {
      photo = Image(
        image: image!,
        fit: fit,
        alignment: alignment,
        gaplessPlayback: true,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        errorBuilder: (context, error, stack) => const SizedBox.expand(),
      );
      if (opacity < 1) photo = Opacity(opacity: opacity, child: photo);
    }
    return AspectRatio(
      aspectRatio: aspectRatio,
      child: ClipRect(
        child: ColoredBox(
          color: background,
          child: Stack(fit: StackFit.expand, children: [?photo, ?overlay]),
        ),
      ),
    );
  }
}

/// The ink check on a selected photo: 22 points square, 6 from the corner.
class CheckBadge extends StatelessWidget {
  const CheckBadge({this.semanticLabel, super.key});

  /// Spoken state, such as "shown"; silent when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    excludeSemantics: true,
    child: const SizedBox.square(
      dimension: 22,
      child: ColoredBox(
        color: InVogueColors.ink,
        child: Center(
          child: InVogueIcon(
            InVogueIcons.check,
            size: 14,
            color: InVogueColors.paper,
          ),
        ),
      ),
    ),
  );
}

/// Places a [CheckBadge] 6 points in from a photo's top-right corner.
class CheckBadgeOverlay extends StatelessWidget {
  const CheckBadgeOverlay({this.semanticLabel, super.key});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.topEnd,
    child: Padding(
      padding: const EdgeInsets.all(6),
      child: CheckBadge(semanticLabel: semanticLabel),
    ),
  );
}

/// The lock glyph centred on a photo behind Go Pro.
class LockOverlay extends StatelessWidget {
  const LockOverlay({this.semanticLabel, super.key});

  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Center(
    child: InVogueIcon(
      InVogueIcons.lock,
      size: 24,
      color: InVogueColors.ink,
      semanticLabel: semanticLabel,
    ),
  );
}
