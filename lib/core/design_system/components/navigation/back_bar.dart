import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The bar on pushed screens: Back on the left; on the right the setup folio
/// ("2 / 6") or nothing. Go Pro uses [BackBar.close] instead: a close on the
/// right. There is never a title in the bar; the screen's title sits below.
class BackBar extends StatelessWidget {
  /// Back, with the setup [step] of [total] when the screen is part of setup.
  const BackBar({required this.onBack, this.step, this.total = 6, super.key})
    : assert(step == null || (step >= 1 && step <= total), 'step out of range'),
      _close = false;

  /// A close on the right and nothing on the left (Go Pro).
  const BackBar.close({required VoidCallback onClose, super.key})
    : onBack = onClose,
      step = null,
      total = 0,
      _close = true;

  /// Back or close.
  final VoidCallback? onBack;

  /// The setup step, 2 to 6; null after setup, where there is no folio.
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
                  builder: (context, state) =>
                      const InVogueIcon(InVogueIcons.close),
                ),
              ]
            : [
                // The caret's drawing sits 6 points inside its box; pull it
                // out so its stroke, not its box, meets the margin.
                Transform.translate(
                  offset: const Offset(-6, 0),
                  child: Pressable(
                    onTap: onBack,
                    semanticLabel: l10n.back,
                    excludeSemantics: true,
                    builder: (context, state) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const InVogueIcon(InVogueIcons.caretLeft, size: 20),
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
