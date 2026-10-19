import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/marked_text.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/foundations/running_rule.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// Underlined text that acts as a link, with a platform-minimum tap area.
/// While [busy], a [RunningRule] runs in place of the underline.
class TextLink extends StatelessWidget {
  const TextLink({
    required this.label,
    required this.onTap,
    this.busy = false,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  /// Working: taps do nothing and screen readers hear it loading.
  final bool busy;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: busy ? null : onTap,
    link: true,
    semanticLabel: label,
    semanticValue: busy ? context.translated.loading : null,
    excludeSemantics: true,
    builder: (context, state) {
      final text = MarkedText(label, style: InVogueType.link, underline: !busy);
      if (!busy) return text;
      return Stack(
        children: [
          text,
          const Positioned(left: 0, right: 0, bottom: 0, child: RunningRule()),
        ],
      );
    },
  );
}
