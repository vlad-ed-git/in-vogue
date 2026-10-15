import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The primary action of a [PicksBar].
enum PicksBarAction { proceed, done }

/// A bottom bar with the number of loved pieces and a primary button.
/// Includes the bottom safe area.
class PicksBar extends StatelessWidget {
  const PicksBar({
    required this.count,
    required this.action,
    required this.onPressed,
    super.key,
  });

  final int count;
  final PicksBarAction action;
  final VoidCallback onPressed;

  /// The button's share of the bar's width.
  static const double buttonWidthFactor = 0.52;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final margin = context.pageMargin;
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: InVogueColors.paper,
        border: Border(top: BorderSide(color: InVogueColors.rule)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          margin,
          InVogueLayout.strokeHairline + InVogueSpace.s3,
          margin,
          InVogueSpace.s3 + MediaQuery.viewPaddingOf(context).bottom,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) => Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      count > 0 ? InVogueIcons.heartFill : InVogueIcons.heart,
                      size: 20,
                      color: count > 0
                          ? InVogueColors.signal
                          : InVogueColors.ink,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        l10n.yourPicksCount(count),
                        style: InVogueType.item.copyWith(
                          fontFeatures: InVogueType.tabularFigures,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: InVogueSpace.s4),
              SizedBox(
                width: constraints.maxWidth * buttonWidthFactor,
                child: switch (action) {
                  PicksBarAction.proceed => InVogueButton.primary(
                    label: l10n.proceed,
                    onPressed: onPressed,
                  ),
                  PicksBarAction.done => InVogueButton.primary(
                    label: l10n.done,
                    icon: InVogueIcons.check,
                    onPressed: onPressed,
                  ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
