import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/text_link.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A caption line under a hairline stating the plan's allowance, with a
/// highlighted Go Pro link.
class PlanLine extends StatelessWidget {
  /// Outfits left; "no outfits left" at zero.
  const PlanLine.free({
    required int this.outfitsLeft,
    required VoidCallback this.onGoPro,
    super.key,
  }) : onProList = false;

  /// "On the Pro list ✓", without a link.
  const PlanLine.onProList({super.key})
    : outfitsLeft = null,
      onGoPro = null,
      onProList = true;

  final int? outfitsLeft;
  final VoidCallback? onGoPro;
  final bool onProList;

  String _allowance(BuildContext context) {
    final l10n = context.translated;
    final outfits = outfitsLeft;
    if (onProList || outfits == null) return l10n.onProList;
    if (outfits == 0) return l10n.planNoOutfits;
    return l10n.planFree(outfits);
  }

  @override
  Widget build(BuildContext context) {
    final style = InVogueType.caption.copyWith(color: InVogueColors.graphite);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: InVogueColors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: InVogueLayout.strokeHairline + InVogueSpace.s4,
        ),
        child: Text.rich(
          TextSpan(
            style: style,
            children: [
              TextSpan(text: _allowance(context)),
              if (onGoPro != null) ...[
                const TextSpan(text: ' · '),
                WidgetSpan(
                  alignment: PlaceholderAlignment.baseline,
                  baseline: TextBaseline.alphabetic,
                  child: TextLink(
                    label: context.translated.goPro,
                    style: InVogueType.caption,
                    highlight: true,
                    onTap: onGoPro,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
