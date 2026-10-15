import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/marked_text.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// A small text action: Change, Skip, Not now, Choose a different photo,
/// Edit, Replace, Go Pro. Ink, underlined 1 point with a 3-point offset,
/// never Rouge. Its tap area reaches the platform minimum without moving it.
class TextLink extends StatelessWidget {
  const TextLink({
    required this.label,
    required this.onTap,
    this.style = InVogueType.link,
    this.color = InVogueColors.ink,
    this.highlight = false,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  /// [InVogueType.link]; [InVogueType.caption] inside the plan line.
  final TextStyle style;
  final Color color;

  /// Set on the Rose highlighter: Go Pro in the plan line.
  final bool highlight;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    link: true,
    semanticLabel: semanticLabel ?? label,
    excludeSemantics: true,
    builder: (context, state) => MarkedText(
      label,
      style: style.copyWith(color: color),
      underline: true,
      highlight: highlight,
    ),
  );
}
