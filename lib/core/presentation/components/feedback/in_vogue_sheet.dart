import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';

/// Shows a modal sheet over the whole app, tab bar included, that slides up
/// over the veil (fades under reduced motion). Closes on a veil tap, a
/// downward drag or back, and completes with the popped value.
Future<T?> showInVogueSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => Navigator.of(context, rootNavigator: true).push(
  InVogueSheetRoute<T>(
    builder: builder,
    reduceMotion: context.reduceMotion,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  ),
);

/// The route used by [showInVogueSheet].
class InVogueSheetRoute<T> extends PopupRoute<T> {
  InVogueSheetRoute({
    required this.builder,
    required this.reduceMotion,
    this.barrierLabel,
  });

  final WidgetBuilder builder;
  final bool reduceMotion;

  @override
  final String? barrierLabel;

  @override
  Color get barrierColor => InVogueColors.veil;

  @override
  bool get barrierDismissible => true;

  @override
  Duration get transitionDuration => InVogueMotion.sheet;

  @override
  Duration get reverseTransitionDuration => InVogueMotion.sheetOut;

  // Preserve: the reduced-motion fade keeps its full length.
  @override
  AnimationController createAnimationController() => AnimationController(
    duration: transitionDuration,
    reverseDuration: reverseTransitionDuration,
    debugLabel: debugLabel,
    vsync: navigator!,
    animationBehavior: AnimationBehavior.preserve,
  );

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Align(
    alignment: Alignment.bottomCenter,
    child: _DraggableSheet(child: Builder(builder: builder)),
  );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (reduceMotion) return FadeTransition(opacity: animation, child: child);
    final curved = CurvedAnimation(
      parent: animation,
      curve: InVogueMotion.enter,
      reverseCurve: InVogueMotion.exit,
    );
    return AnimatedBuilder(
      animation: curved,
      child: child,
      builder: (context, child) => FractionalTranslation(
        translation: Offset(0, 1 - curved.value),
        child: child,
      ),
    );
  }
}

class _DraggableSheet extends StatefulWidget {
  const _DraggableSheet({required this.child});

  final Widget child;

  @override
  State<_DraggableSheet> createState() => _DraggableSheetState();
}

class _DraggableSheetState extends State<_DraggableSheet> {
  static const _flingVelocity = 700.0;
  static const _closeFraction = 0.3;

  double _drag = 0;
  bool _dragging = false;

  void _update(DragUpdateDetails details) =>
      setState(() => _drag = math.max(0, _drag + details.delta.dy));

  void _end(DragEndDetails details) {
    final height = context.size?.height ?? 1;
    final close =
        details.velocity.pixelsPerSecond.dy > _flingVelocity ||
        _drag > height * _closeFraction;
    setState(() {
      _dragging = false;
      if (!close) _drag = 0;
    });
    if (close) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.translucent,
    onVerticalDragStart: (_) => setState(() => _dragging = true),
    onVerticalDragUpdate: _update,
    onVerticalDragEnd: _end,
    child: AnimatedContainer(
      duration: _dragging ? Duration.zero : InVogueMotion.base,
      curve: InVogueMotion.standard,
      transform: Matrix4.translationValues(0, _drag, 0),
      child: widget.child,
    ),
  );
}

/// A sheet panel: a grabber above [child], with page margins and the bottom
/// safe area. Scrolls when taller than the screen; text fields work in it.
class InVogueSheet extends StatelessWidget {
  const InVogueSheet({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: media.size.height - media.viewPadding.top,
      ),
      child: Material(
        color: InVogueColors.paper,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.pageMargin,
            InVogueSpace.s3,
            context.pageMargin,
            InVogueSpace.s3 +
                math.max(media.viewPadding.bottom, media.viewInsets.bottom),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: SizedBox(
                  width: 36,
                  height: 4,
                  child: ColoredBox(color: InVogueColors.rule),
                ),
              ),
              const SizedBox(height: InVogueSpace.s4),
              Flexible(child: SingleChildScrollView(child: child)),
            ],
          ),
        ),
      ),
    );
  }
}

/// A sheet title with an optional subtitle.
class InVogueSheetHeader extends StatelessWidget {
  const InVogueSheetHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: subtitle == null ? InVogueSpace.s3 : 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            style: InVogueType.section,
            textScaler: context.displayTextScaler,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(
              top: InVogueSpace.s1,
              bottom: InVogueSpace.s3,
            ),
            child: Text(
              subtitle!,
              style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
            ),
          ),
      ],
    ),
  );
}

/// A choice row with a check when [selected].
class InVogueSheetOption extends StatelessWidget {
  const InVogueSheetOption({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: onTap,
    button: true,
    selected: selected,
    inMutuallyExclusiveGroup: true,
    expandTapTarget: false,
    // The 56-point minimum includes the hairline, as in CSS.
    builder: (context, state) => DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: InVogueColors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: InVogueLayout.strokeHairline),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: 56 - InVogueLayout.strokeHairline,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: selected ? InVogueType.bodyStrong : InVogueType.body,
                ),
              ),
              if (selected) const Icon(InVogueIcons.check),
            ],
          ),
        ),
      ),
    ),
  );
}
