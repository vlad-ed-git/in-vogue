import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/running_rule.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';

/// A photo in a fixed-ratio frame that shows [background] while the photo
/// is missing or loading.
class PhotoSlot extends StatelessWidget {
  const PhotoSlot({
    this.image,
    this.aspectRatio = InVogueLayout.portraitAspectRatio,
    this.fit = BoxFit.cover,
    this.background = InVogueColors.accent,
    this.semanticLabel,
    this.overlay,
    this.showLoading = false,
    this.fallback,
    super.key,
  });

  final ImageProvider? image;

  /// Width over height.
  final double aspectRatio;
  final BoxFit fit;

  /// Fill shown while there is no photo.
  final Color background;

  /// Describes the photo; null hides it from screen readers.
  final String? semanticLabel;

  /// Drawn over the photo.
  final Widget? overlay;

  /// Runs a [RunningRule] along the bottom until the photo's first frame,
  /// for photos fetched from the web.
  final bool showLoading;

  /// Shown in place of a photo that can't be drawn, such as one whose file
  /// is gone; [background] when null.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    Widget? photo;
    if (image != null) {
      photo = Image(
        image: image!,
        fit: fit,
        gaplessPlayback: true,
        semanticLabel: semanticLabel,
        excludeFromSemantics: semanticLabel == null,
        frameBuilder: showLoading ? _whileLoading : null,
        errorBuilder: (context, error, stack) =>
            fallback ?? const SizedBox.expand(),
      );
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

Widget _whileLoading(
  BuildContext context,
  Widget child,
  int? frame,
  bool wasSynchronouslyLoaded,
) {
  if (wasSynchronouslyLoaded || frame != null) return child;
  return Stack(
    fit: StackFit.expand,
    children: [
      child,
      const Align(alignment: Alignment.bottomCenter, child: RunningRule()),
    ],
  );
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
          child: Icon(InVogueIcons.check, size: 14, color: InVogueColors.paper),
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
