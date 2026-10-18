import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';

/// The loading motion: a 2-point bar a third as wide as the rule runs from
/// the start to the end every [InVogueMotion.run], with the curtain easing.
/// With reduced motion the bar fills the width and fades in and out.
class RunningRule extends StatefulWidget {
  const RunningRule({this.color = InVogueColors.ink, super.key})
    : track = null,
      padding = EdgeInsets.zero;

  /// Stands in for content still loading: the bar over a hairline, below
  /// the content above it.
  const RunningRule.content({super.key})
    : color = InVogueColors.ink,
      track = InVogueColors.rule,
      padding = const EdgeInsets.only(top: InVogueSpace.s5);

  final Color color;

  /// A hairline under the bar.
  final Color? track;
  final EdgeInsets padding;

  /// Width of the bar over the width of the rule.
  static const double barFraction = 1 / 3;

  @override
  State<RunningRule> createState() => _RunningRuleState();
}

class _RunningRuleState extends State<RunningRule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: InVogueMotion.run,
  );
  bool? _reduced;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = context.reduceMotion;
    if (reduced == _reduced) return;
    _reduced = reduced;
    _controller
      ..value = 0
      ..repeat(reverse: reduced);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bar = ColoredBox(color: widget.color);
    return Semantics(
      excludeSemantics: true,
      child: Padding(
        padding: widget.padding,
        child: SizedBox(
          height: InVogueLayout.strokeSelect,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.track case final track?)
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SizedBox(
                    height: InVogueLayout.strokeHairline,
                    width: double.infinity,
                    child: ColoredBox(color: track),
                  ),
                ),
              ClipRect(
                child: _reduced!
                    ? FadeTransition(
                        opacity: _controller.drive(
                          Tween<double>(
                            begin: 0.25,
                            end: 1,
                          ).chain(CurveTween(curve: Curves.easeInOut)),
                        ),
                        child: bar,
                      )
                    : AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) => Align(
                          // -2 puts the bar just before the start, 2 just
                          // past the end.
                          alignment: Alignment(
                            InVogueMotion.curtain.transform(_controller.value) *
                                    4 -
                                2,
                            0,
                          ),
                          child: child,
                        ),
                        child: FractionallySizedBox(
                          widthFactor: RunningRule.barFraction,
                          heightFactor: 1,
                          child: bar,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
