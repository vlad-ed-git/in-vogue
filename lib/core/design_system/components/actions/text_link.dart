import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/marked_text.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// Underlined text that acts as a link, with a platform-minimum tap area.
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

  final TextStyle style;
  final Color color;

  /// Paints the Rose highlight behind the label.
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
