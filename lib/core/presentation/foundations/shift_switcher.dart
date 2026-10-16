import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';

/// Switches to a new [child] (told apart by its key) with a short sideways
/// shift: the old child fades out moving away, the new one fades in from
/// the side [direction] points to. Crossfades in place when [direction] is
/// 0, and under reduced motion.
class ShiftSwitcher extends StatelessWidget {
  const ShiftSwitcher({required this.child, this.direction = 0, super.key});

  final Widget child;

  /// 1: the new child comes in from the end, as when moving forward; -1:
  /// from the start; 0: in place.
  final int direction;

  static const duration = Duration(milliseconds: 360);

  /// How far each child moves, in points.
  static const double distance = 24;

  /// The old child is gone after this share of [duration]; the new one
  /// starts at [enterFrom].
  static const leaveBy = 0.4;
  static const enterFrom = 0.3;

  @override
  Widget build(BuildContext context) {
    final still = context.reduceMotion;
    final shift = still ? 0 : direction.sign;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final dx = distance * shift * (rtl ? -1 : 1);
    return AnimatedSwitcher(
      duration: still ? InVogueMotion.base : duration,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      transitionBuilder: (shown, animation) {
        final entering = shown.key == child.key;
        return AnimatedBuilder(
          animation: animation,
          child: shown,
          builder: (context, shown) {
            final t = animation.value;
            final double opacity;
            final double offset;
            if (still) {
              opacity = InVogueMotion.standard.transform(t);
              offset = 0;
            } else if (entering) {
              final arrive = InVogueMotion.enter.transform(
                ((t - enterFrom) / (1 - enterFrom)).clamp(0.0, 1.0),
              );
              opacity = arrive;
              offset = dx * (1 - arrive);
            } else {
              // Runs from 1 to 0 as the new child arrives.
              final leave = InVogueMotion.exit.transform(
                ((1 - t) / leaveBy).clamp(0.0, 1.0),
              );
              opacity = 1 - leave;
              offset = -dx * leave;
            }
            return IgnorePointer(
              ignoring: !entering,
              child: Opacity(
                opacity: opacity,
                child: Transform.translate(
                  offset: Offset(offset, 0),
                  child: shown,
                ),
              ),
            );
          },
        );
      },
      child: child,
    );
  }
}
