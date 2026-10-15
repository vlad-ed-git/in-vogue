import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';

/// A photo in a fixed-ratio frame that shows [background] while the photo
/// is missing or loading.
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

  /// Width over height.
  final double aspectRatio;
  final BoxFit fit;
  final Alignment alignment;

  final double opacity;

  /// Fill shown while there is no photo.
  final Color background;

  /// Describes the photo; null hides it from screen readers.
  final String? semanticLabel;

  /// Drawn over the photo.
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

/// A 22-point ink square with a paper check.
class CheckBadge extends StatelessWidget {
  const CheckBadge({this.semanticLabel, super.key});

  /// Read by screen readers; silent when null.
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

/// A [CheckBadge] 6 points in from the top-end corner.
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

/// A centred lock icon.
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
