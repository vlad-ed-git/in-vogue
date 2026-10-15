import 'dart:math' as math;
import 'dart:ui' show SemanticsRole, lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// Today | Tomorrow on Home (and Before | After on Makeup): two words in the
/// `tab` style over a hairline. The selected one is ink at weight 700 with a
/// 2-point ink rule that slides to it; the other is graphite at 500. The
/// selected day's short date sits flush right in `meta`.
///
/// Not a filled segmented control, never a third day. Switching never starts
/// a try-on. Screen readers hear a tab list.
class DaySwitch extends StatefulWidget {
  const DaySwitch({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.date,
    super.key,
  }) : assert(labels.length == 2, 'a day switch has two tabs');

  /// "Today", "Tomorrow" (or "Before", "After").
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// The selected day's short date, such as "Thu 16 Oct".
  final String? date;

  /// The switch's height at the default text size, including its hairline.
  static const double height = 40;

  @override
  State<DaySwitch> createState() => _DaySwitchState();
}

class _DaySwitchState extends State<DaySwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: InVogueMotion.base,
    value: 1,
  );
  late final CurvedAnimation _progress = CurvedAnimation(
    parent: _slide,
    curve: InVogueMotion.standard,
  );
  late int _from = widget.selectedIndex;

  @override
  void didUpdateWidget(DaySwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _from = oldWidget.selectedIndex;
      if (context.reduceMotion) {
        _slide.value = 1;
      } else {
        _slide.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _progress.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabScale = context.displayTextScaler.scale(1);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    // The CSS box: tabs 24 tall plus 8 and the 2-point rule, 6 below the top;
    // the date 20 tall, 10 above the hairline. Taller text grows the box.
    final height = math.max(
      DaySwitch.height,
      math.max(24 * tabScale + 16, 20 * textScale + 20),
    );
    return Semantics(
      role: SemanticsRole.tabBar,
      container: true,
      explicitChildNodes: true,
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: InVogueColors.rule)),
          ),
          child: CustomMultiChildLayout(
            delegate: _DaySwitchLayout(
              selected: widget.selectedIndex,
              from: _from,
              progress: _progress,
              hasDate: widget.date != null,
            ),
            children: [
              for (var i = 0; i < 2; i++)
                LayoutId(id: i, child: _tab(context, i)),
              if (widget.date != null)
                LayoutId(
                  id: _DaySwitchLayout.dateId,
                  // Spoken with the selected tab instead.
                  child: ExcludeSemantics(
                    child: Text(
                      widget.date!,
                      style: InVogueType.meta.copyWith(
                        color: InVogueColors.graphite,
                      ),
                    ),
                  ),
                ),
              LayoutId(
                id: _DaySwitchLayout.ruleId,
                child: ColoredBox(color: InVogueColors.ink),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index) {
    final selected = index == widget.selectedIndex;
    return Pressable(
      onTap: selected ? () {} : () => widget.onSelected(index),
      role: SemanticsRole.tab,
      selected: selected,
      haptic: selected ? InVogueHaptic.none : InVogueHaptic.selection,
      semanticLabel: widget.labels[index],
      semanticValue: selected ? widget.date : null,
      excludeSemantics: true,
      builder: (context, state) => Padding(
        padding: const EdgeInsets.only(
          bottom: InVogueSpace.s2 + InVogueLayout.strokeSelect,
        ),
        child: TweenAnimationBuilder<Color?>(
          tween: ColorTween(
            end: selected ? InVogueColors.ink : InVogueColors.graphite,
          ),
          duration: InVogueMotion.quick,
          curve: InVogueMotion.standard,
          builder: (context, color, _) => Text(
            widget.labels[index],
            textScaler: context.displayTextScaler,
            style: (selected ? InVogueType.tabActive : InVogueType.tab)
                .copyWith(color: color),
          ),
        ),
      ),
    );
  }
}

class _DaySwitchLayout extends MultiChildLayoutDelegate {
  _DaySwitchLayout({
    required this.selected,
    required this.from,
    required this.progress,
    required this.hasDate,
  }) : super(relayout: progress);

  static const dateId = 'date';
  static const ruleId = 'rule';
  static const gap = InVogueSpace.s6;

  final int selected;
  final int from;
  final Animation<double> progress;
  final bool hasDate;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    final rects = <Rect>[];
    var x = 0.0;
    for (var i = 0; i < 2; i++) {
      final tab = layoutChild(i, loose);
      // A tab overhangs the hairline by a point, so its rule covers it.
      final rect = Offset(x, size.height - tab.height) & tab;
      positionChild(i, rect.topLeft);
      rects.add(rect);
      x = rect.right + gap;
    }
    if (hasDate) {
      final room = math.max(0.0, size.width - rects.last.right - gap);
      final date = layoutChild(dateId, BoxConstraints(maxWidth: room));
      positionChild(
        dateId,
        Offset(
          size.width - date.width,
          size.height - InVogueLayout.strokeHairline - 10 - date.height,
        ),
      );
    }
    final t = progress.value;
    final left = lerpDouble(rects[from].left, rects[selected].left, t)!;
    final width = lerpDouble(rects[from].width, rects[selected].width, t)!;
    layoutChild(
      ruleId,
      BoxConstraints.tight(Size(width, InVogueLayout.strokeSelect)),
    );
    positionChild(
      ruleId,
      Offset(left, size.height - InVogueLayout.strokeSelect),
    );
  }

  @override
  bool shouldRelayout(_DaySwitchLayout oldDelegate) =>
      oldDelegate.selected != selected ||
      oldDelegate.from != from ||
      oldDelegate.hasDate != hasDate ||
      oldDelegate.progress != progress;
}
