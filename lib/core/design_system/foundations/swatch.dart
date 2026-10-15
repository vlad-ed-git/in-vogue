import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';

/// A garment's real colour as a dot: data, never decoration. It is the only
/// round thing in In Vogue, ringed with `line` so pale colours stay visible.
class Swatch extends StatelessWidget {
  const Swatch({
    required this.color,
    this.size = small,
    this.selected = false,
    super.key,
  });

  /// In tiles, the Shop page and colour lines.
  static const double small = 12;

  /// In the colour sheet.
  static const double large = 28;

  final Color color;
  final double size;

  /// The chosen colour: a 2-point paper gap, then 2 points of ink.
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
