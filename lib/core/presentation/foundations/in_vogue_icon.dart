import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/svg_path.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';

/// Draws one of the [InVogueIcons]. Colour falls back to the ambient
/// [IconTheme], then ink. Hidden from screen readers without a
/// [semanticLabel].
class InVogueIcon extends StatelessWidget {
  const InVogueIcon(
    this.icon, {
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final InVogueIcons icon;

  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final paint = CustomPaint(
      size: Size.square(size),
      painter: GridPathPainter(
        pathData: icon.pathData,
        color: color ?? IconTheme.of(context).color ?? InVogueColors.ink,
      ),
    );
    if (semanticLabel == null) return ExcludeSemantics(child: paint);
    return Semantics(label: semanticLabel, image: true, child: paint);
  }
}

/// Fills SVG path data drawn on a 256-unit grid, scaled to its size.
class GridPathPainter extends CustomPainter {
  const GridPathPainter({required this.pathData, required this.color});

  static const double grid = 256;

  final String pathData;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / grid, size.height / grid)
      ..drawPath(
        SvgPath.parse(pathData),
        Paint()
          ..color = color
          ..isAntiAlias = true,
      )
      ..restore();
  }

  @override
  bool shouldRepaint(GridPathPainter oldDelegate) =>
      oldDelegate.pathData != pathData || oldDelegate.color != color;
}
