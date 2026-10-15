import 'dart:math' as math;
import 'dart:ui' show Path, PathMetric;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/layout_blocks.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A check that draws itself, then a fading-in headline and line, and a
/// back button. Plays a medium haptic once the check is drawn.
class ProConfirmation extends StatefulWidget {
  const ProConfirmation({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<ProConfirmation> createState() => _ProConfirmationState();
}

class _ProConfirmationState extends State<ProConfirmation>
    with TickerProviderStateMixin {
  late final AnimationController _draw;
  late final AnimationController _words;
  late final CurvedAnimation _stroke;
  late final CurvedAnimation _fade;

  @override
  void initState() {
    super.initState();
    _draw = AnimationController(vsync: this, duration: InVogueMotion.draw)
      ..addStatusListener((status) {
        if (!status.isCompleted) return;
        InVogueHaptic.medium.play();
        _words.forward();
      });
    _words = AnimationController(vsync: this, duration: InVogueMotion.base);
    _stroke = CurvedAnimation(parent: _draw, curve: InVogueMotion.enter);
    _fade = CurvedAnimation(parent: _words, curve: InVogueMotion.standard);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_draw.isDismissed && !_draw.isAnimating) {
      if (context.reduceMotion) {
        _draw.value = 1;
        _words.value = 1;
      } else {
        _draw.forward();
      }
    }
  }

  @override
  void dispose() {
    _stroke.dispose();
    _fade.dispose();
    _draw.dispose();
    _words.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CustomPaint(
            size: const Size.square(72),
            painter: DrawnCheckPainter(progress: _stroke),
          ),
        ),
        FadeTransition(
          opacity: _fade,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: InVogueSpace.s6),
              Semantics(
                liveRegion: true,
                child: ScreenTitle(l10n.onTheList, style: InVogueType.headline),
              ),
              const SizedBox(height: InVogueSpace.s3),
              Text(
                l10n.proSoon,
                style: InVogueType.body.copyWith(color: InVogueColors.graphite),
              ),
            ],
          ),
        ),
        const SizedBox(height: InVogueSpace.s6),
        InVogueButton.primary(
          label: l10n.backToInVogue,
          onPressed: widget.onBack,
        ),
      ],
    );
  }
}

/// A 3-point ink check on a 72-point grid, drawn up to [progress].
class DrawnCheckPainter extends CustomPainter {
  DrawnCheckPainter({required this.progress}) : super(repaint: progress);

  final Animation<double> progress;

  /// Dash length through which the stroke is revealed, as in CSS.
  static const double dash = 80;

  static final Path _check = Path()
    ..moveTo(14, 38)
    ..lineTo(29, 52)
    ..lineTo(58, 20);

  @override
  void paint(Canvas canvas, Size size) {
    final metric = _check.computeMetrics().single;
    final visible = math.min(metric.length, dash * progress.value);
    if (visible <= 0) return;
    canvas
      ..save()
      ..scale(size.width / 72, size.height / 72)
      ..drawPath(
        _extract(metric, visible),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.square
          ..strokeJoin = StrokeJoin.miter
          ..color = InVogueColors.ink,
      )
      ..restore();
  }

  static Path _extract(PathMetric metric, double length) =>
      metric.extractPath(0, length);

  @override
  bool shouldRepaint(DrawnCheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
