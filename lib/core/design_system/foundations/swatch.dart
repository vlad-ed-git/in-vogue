import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';

/// A colour dot with a thin ring; [selected] adds an outer ink ring.
class Swatch extends StatelessWidget {
  const Swatch({
    required this.color,
    this.size = small,
    this.selected = false,
    super.key,
  });

  static const double small = 12;

  static const double large = 28;

  final Color color;
  final double size;

  final bool selected;

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: Size.square(size),
    painter: SwatchPainter(color: color, selected: selected),
  );
}

/// Paints a [Swatch].
class SwatchPainter extends CustomPainter {
  const SwatchPainter({required this.color, required this.selected});

  final Color color;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    const hairline = InVogueLayout.strokeHairline;
    const select = InVogueLayout.strokeSelect;
    canvas
      ..drawCircle(center, radius, Paint()..color = color)
      ..drawCircle(
        center,
        radius - hairline / 2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = hairline
          ..color = InVogueColors.line,
      );
    if (selected) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = select;
      canvas
        ..drawCircle(
          center,
          radius + select / 2,
          ring..color = InVogueColors.paper,
        )
        ..drawCircle(
          center,
          radius + select * 1.5,
          ring..color = InVogueColors.ink,
        );
    }
  }

  @override
  bool shouldRepaint(SwatchPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.selected != selected;
}
