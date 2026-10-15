import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/temperature_text.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';

/// A [TemperatureText] that rolls to a new value: the old one rises and
/// fades out, the new one rises into place. Crossfades under reduced motion.
class RollingTemperature extends StatefulWidget {
  const RollingTemperature(
    this.degrees, {
    this.style = InVogueType.numeral,
    super.key,
  });

  final int degrees;
  final TextStyle style;

  @override
  State<RollingTemperature> createState() => _RollingTemperatureState();
}

class _RollingTemperatureState extends State<RollingTemperature>
    with SingleTickerProviderStateMixin {
  static const _total = Duration(milliseconds: 280);

  // Preserve: the reduced-motion crossfade keeps its full length.
  late final AnimationController _roll;

  @override
  void initState() {
    super.initState();
    _roll = AnimationController(
      vsync: this,
      duration: _total,
      value: 1,
      animationBehavior: AnimationBehavior.preserve,
    );
  }

  int? _previous;
  bool _crossfade = false;

  @override
  void didUpdateWidget(RollingTemperature oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.degrees != widget.degrees) {
      _previous = oldWidget.degrees;
      _crossfade = context.reduceMotion;
      _roll.duration = _crossfade ? InVogueMotion.base : _total;
      _roll.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _roll.dispose();
    super.dispose();
  }

  /// Eased progress of the window [start]–[end] of the roll.
  double _window(Duration start, Duration end, Curve curve) {
    final now = _total * _roll.value;
    final t = (now - start).inMicroseconds / (end - start).inMicroseconds;
    return curve.transform(t.clamp(0.0, 1.0));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _roll,
    builder: (context, _) {
      final current = TemperatureText(widget.degrees, style: widget.style);
      if (_previous == null || _roll.isCompleted) return current;
      final old = TemperatureText(_previous!, style: widget.style);
      final double outgoing;
      final double incoming;
      double rise = 0;
      double arrive = 0;
      if (_crossfade) {
        incoming = InVogueMotion.standard.transform(_roll.value);
        outgoing = 1 - incoming;
      } else {
        final leave = _window(
          Duration.zero,
          InVogueMotion.quick,
          InVogueMotion.exit,
        );
        final enter = _window(
          InVogueMotion.rollDelay,
          InVogueMotion.rollDelay + InVogueMotion.base,
          InVogueMotion.enter,
        );
        outgoing = 1 - leave;
        incoming = enter;
        rise = -InVogueMotion.rollDistance * leave;
        arrive = lerpDouble(InVogueMotion.rollDistance, 0, enter)!;
      }
      return ClipRect(
        child: Stack(
          children: [
            Positioned(
              left: 0,
              bottom: 0,
              child: Transform.translate(
                offset: Offset(0, rise),
                child: Opacity(opacity: outgoing, child: old),
              ),
            ),
            Transform.translate(
              offset: Offset(0, arrive),
              child: Opacity(opacity: incoming, child: current),
            ),
          ],
        ),
      );
    },
  );
}
