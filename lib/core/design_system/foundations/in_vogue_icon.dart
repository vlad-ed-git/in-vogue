import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/design_system/foundations/svg_path.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';

/// One of the [InVogueIcons], drawn at [size] points from the spec's path
/// data. Its colour is [color], else the ambient [IconTheme]'s, else ink.
/// Decorative unless it has a [semanticLabel].
class InVogueIcon extends StatelessWidget {
  const InVogueIcon(
    this.icon, {
    this.size = 24,
    this.color,
    this.semanticLabel,
    super.key,
  });

  final InVogueIcons icon;

  /// 24 for interface icons, 20 for small ones, 22 in buttons and hearts.
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

/// Fills SVG path data drawn on Phosphor's 256-unit grid, scaled to the
/// size it is given.
class GridPathPainter extends CustomPainter {
  const GridPathPainter({required this.pathData, required this.color});

  /// The 256-unit grid of Phosphor Icons.
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
