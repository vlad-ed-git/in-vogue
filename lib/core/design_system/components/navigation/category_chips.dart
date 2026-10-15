import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// A horizontally scrolling row of single-choice chips.
///
/// Adds the page margin itself, so it can scroll to the screen edges; its
/// 6-point vertical padding gives each chip a 48-point tap area.
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

  /// Screen-reader name of the group.
  final String? semanticLabel;

  static const double chipHeight = 36;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    explicitChildNodes: true,
    label: semanticLabel,
    // Takes the row's own height under any constraints.
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
