import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// One-choice filters on Pick what you like: All · Coats & jackets ·
/// Knitwear · Tops · Trousers & jeans · Skirts & shorts · Dresses.
///
/// Square chips, 36 tall, with a 1-point ink edge and the label in the link
/// size; the selected one is filled ink with paper words. One at a time. The
/// row scrolls sideways and runs past the right margin, so the cut-off chip
/// shows there is more.
///
/// Place it outside the page margin: it adds the margin itself, so the row
/// can run to the screen's edge. Its 6-point padding above and below lets
/// each chip's tap area reach 48.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.semanticLabel,
    super.key,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// The group's name for screen readers, such as "Categories".
  final String? semanticLabel;

  /// A chip's height.
  static const double chipHeight = 36;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: semanticLabel,
    // Hug the row's own height whatever the parent offers.
    child: Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(
          horizontal: context.pageMargin,
          vertical: 6,
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: InVogueSpace.s2),
              _Chip(
                label: labels[i],
                selected: i == selectedIndex,
                onTap: () => onSelected(i),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  void _select(BuildContext context) {
    onTap();
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: context.reduceMotion ? Duration.zero : InVogueMotion.base,
      curve: InVogueMotion.standard,
    );
  }

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: () => _select(context),
    toggled: selected,
    haptic: selected ? InVogueHaptic.none : InVogueHaptic.selection,
    semanticLabel: label,
    excludeSemantics: true,
    builder: (context, state) => DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? InVogueColors.ink : null,
        border: Border.all(color: InVogueColors.ink),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: CategoryChips.chipHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: InVogueType.link.copyWith(
                color: selected ? InVogueColors.paper : InVogueColors.ink,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
