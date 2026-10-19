import 'dart:math' as math;
import 'dart:ui' show SemanticsRole, lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';

/// Tabs over a hairline; a 2-point rule slides under the selected one.
/// An optional [date] sits on the right. Read as a tab list.
class DaySwitch extends StatefulWidget {
  const DaySwitch({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.date,
    super.key,
  }) : assert(labels.length >= 2, 'a day switch has two tabs or more');

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  /// Shown on the right and read with the selected tab.
  final String? date;

  /// Height at the default text size, hairline included.
  static const double height = 40;

  @override
  State<DaySwitch> createState() => _DaySwitchState();
}

class _DaySwitchState extends State<DaySwitch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide;
  late final CurvedAnimation _progress;
  late int _from = widget.selectedIndex;

  @override
  void initState() {
    super.initState();
    _slide = AnimationController(
      vsync: this,
      duration: InVogueMotion.base,
      value: 1,
    );
    _progress = CurvedAnimation(parent: _slide, curve: InVogueMotion.standard);
  }

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
    // As in CSS: tabs (24 + 8 + 2-point rule) start 6 from the top; the date
    // (20) sits 10 above the hairline. Larger text grows the box.
    final height = math.max(
      DaySwitch.height,
      math.max(24 * tabScale + 16, 20 * textScale + 20),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final tabs = _tabsWidth(context);
        final room = constraints.maxWidth;
        // The date gives way to the tabs; it is still spoken with them.
        final showDate =
            widget.date != null &&
            tabs + _DaySwitchLayout.gap + _dateWidth(context) <= room;
        Widget line = SizedBox(
          height: height,
          child: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: InVogueColors.rule)),
            ),
            child: CustomMultiChildLayout(
              delegate: _DaySwitchLayout(
                tabs: widget.labels.length,
                selected: widget.selectedIndex,
                from: _from,
                progress: _progress,
                hasDate: showDate,
              ),
              children: [
                for (var i = 0; i < widget.labels.length; i++)
                  LayoutId(id: i, child: _tab(i)),
                if (showDate)
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
        );
        // Tabs that cannot fit shrink together rather than run off.
        if (tabs > room) {
          line = FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(width: tabs, child: line),
          );
        }
        return Semantics(
          role: SemanticsRole.tabBar,
          container: true,
          explicitChildNodes: true,
          child: line,
        );
      },
    );
  }

  /// Width of the tabs and the gaps between them, each label set as if
  /// selected.
  double _tabsWidth(BuildContext context) {
    var width = _DaySwitchLayout.gap * (widget.labels.length - 1);
    for (final label in widget.labels) {
      width += _textWidth(
        context,
        label,
        InVogueType.tabActive,
        context.displayTextScaler,
      );
    }
    return width;
  }

  double _dateWidth(BuildContext context) => _textWidth(
    context,
    widget.date!,
    InVogueType.meta,
    MediaQuery.textScalerOf(context),
  );

  static double _textWidth(
    BuildContext context,
    String text,
    TextStyle style,
    TextScaler scaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textScaler: scaler,
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    final width = painter.width;
    painter.dispose();
    return width.ceilToDouble();
  }

  Widget _tab(int index) {
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
    required this.tabs,
    required this.selected,
    required this.from,
    required this.progress,
    required this.hasDate,
  }) : super(relayout: progress);

  static const dateId = 'date';
  static const ruleId = 'rule';
  static const gap = InVogueSpace.s6;

  final int tabs;
  final int selected;
  final int from;
  final Animation<double> progress;
  final bool hasDate;

  @override
  void performLayout(Size size) {
    final loose = BoxConstraints.loose(size);
    final rects = <Rect>[];
    var x = 0.0;
    for (var i = 0; i < tabs; i++) {
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
      oldDelegate.tabs != tabs ||
      oldDelegate.selected != selected ||
      oldDelegate.from != from ||
      oldDelegate.hasDate != hasDate ||
      oldDelegate.progress != progress;
}
