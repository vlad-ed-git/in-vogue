import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A bar with Back on the left and an optional "2 / 6" step folio on the
/// right.
class BackBar extends StatelessWidget {
  /// Shows "[step] / [total]" when [step] is set.
  const BackBar({required this.onBack, this.step, this.total = 6, super.key})
    : assert(step == null || (step >= 1 && step <= total), 'step out of range'),
      _close = false;

  /// A bar with only a close button, on the right.
  const BackBar.close({required VoidCallback onClose, super.key})
    : onBack = onClose,
      step = null,
      total = 0,
      _close = true;

  /// Back or close action.
  final VoidCallback? onBack;

  /// Current step; no folio when null.
  final int? step;
  final int total;
  final bool _close;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: InVogueLayout.topBarHeight),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _close
            ? [
                const SizedBox.shrink(),
                Pressable(
                  onTap: onBack,
                  semanticLabel: l10n.close,
                  builder: (context, state) => const Icon(InVogueIcons.close),
                ),
              ]
            : [
                // Aligns the caret's stroke, not its box, with the margin.
                Transform.translate(
                  offset: const Offset(-6, 0),
                  child: Pressable(
                    onTap: onBack,
                    semanticLabel: l10n.back,
                    excludeSemantics: true,
                    builder: (context, state) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(InVogueIcons.caretLeft, size: 20),
                        const SizedBox(width: 2),
                        Text(l10n.back, style: InVogueType.link),
                      ],
                    ),
                  ),
                ),
                if (step != null) ...[
                  const SizedBox(width: InVogueSpace.s4),
                  Text(
                    l10n.setupFolio(step!, total),
                    style: InVogueType.meta.copyWith(
                      color: InVogueColors.graphite,
                      fontFeatures: InVogueType.tabularFigures,
                    ),
                  ),
                ],
              ],
      ),
    );
  }
}
