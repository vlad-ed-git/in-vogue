import 'dart:ui' show Path;

import 'package:path_parsing/path_parsing.dart';

/// Turns SVG path data into a [Path], once per distinct string.
///
/// Icons and weather glyphs are drawn from the spec's own Phosphor SVG data
/// on its 256-unit grid; parsing is cached because the same few paths repaint
/// on every frame of a glyph's loop.
abstract final class SvgPath {
  static final Map<String, Path> _cache = {};

  /// The parsed path for [data]. Treat it as read-only: transform a copy.
  static Path parse(String data) => _cache.putIfAbsent(data, () {
    final proxy = _PathProxy();
    writeSvgPathDataToPath(data, proxy);
    return proxy.path;
  });
}

class _PathProxy extends PathProxy {
  final Path path = Path();

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) => path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
