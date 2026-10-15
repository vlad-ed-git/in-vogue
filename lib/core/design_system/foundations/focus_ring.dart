import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';

/// Draws a focus ring outside [child]: a 2-point paper gap, then 2 points of
/// ink.
class FocusRing extends StatelessWidget {
  const FocusRing({required this.visible, required this.child, super.key});

  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) => CustomPaint(
    foregroundPainter: visible ? const FocusRingPainter() : null,
    child: child,
  );
}

/// Paints a focus ring around its box.
class FocusRingPainter extends CustomPainter {
  const FocusRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = InVogueLayout.strokeSelect;
    final box = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas
      ..drawRect(box.inflate(stroke / 2), paint..color = InVogueColors.paper)
      ..drawRect(box.inflate(stroke * 1.5), paint..color = InVogueColors.ink);
  }

  @override
  bool shouldRepaint(FocusRingPainter oldDelegate) => false;
}
