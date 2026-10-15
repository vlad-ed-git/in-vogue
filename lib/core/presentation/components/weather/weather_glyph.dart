import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph_paths.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/svg_path.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';

/// A weather glyph and its loop timing.
enum WeatherGlyphType {
  sun('sun', Duration(milliseconds: 2400)),
  cloudSun('cloud-sun', Duration(milliseconds: 2400)),
  cloud('cloud', Duration(milliseconds: 2400)),
  cloudFog('cloud-fog', Duration(milliseconds: 2400)),
  cloudRain(
    'cloud-rain',
    Duration(milliseconds: 1200),
    stagger: Duration(milliseconds: 200),
  ),
  cloudSnow(
    'cloud-snow',
    Duration(milliseconds: 1800),
    stagger: Duration(milliseconds: 300),
  ),
  cloudLightning('cloud-lightning', Duration(milliseconds: 2400)),
  wind('wind', Duration(milliseconds: 1600));

  const WeatherGlyphType(this.specName, this.cycle, {this.stagger});

  /// Source file name, without `-light.svg`.
  final String specName;

  /// Length of one loop cycle.
  final Duration cycle;

  /// Delay between the falling drops or flakes.
  final Duration? stagger;

  /// Cycles played before the glyph rests.
  static const int cycles = 3;

  /// Gust speed from which a dry code maps to [wind].
  static const double windyGustsKmh = 50;

  /// Total loop length, staggered parts included.
  Duration get loop => cycle * cycles + (stagger ?? Duration.zero) * 2;

  /// The glyph for a WMO weather code; null for an unknown code.
  static WeatherGlyphType? fromWmo(int code, {double? gustsKmh}) {
    final dry = switch (code) {
      0 => sun,
      1 || 2 => cloudSun,
      3 => cloud,
      45 || 48 => cloudFog,
      _ => null,
    };
    if (dry != null) {
      return (gustsKmh ?? 0) >= windyGustsKmh ? wind : dry;
    }
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return cloudRain;
    }
    if ((code >= 71 && code <= 77) || code == 85 || code == 86) {
      return cloudSnow;
    }
    if (code >= 95 && code <= 99) return cloudLightning;
    return null;
  }
}

/// A weather glyph that plays its loop three times, then rests on its
/// first frame.
///
/// Plays on first build and whenever [type] or [playKey] changes. Stays still
/// under reduced motion, in a muted [TickerMode] and in the background.
class WeatherGlyph extends StatefulWidget {
  const WeatherGlyph(
    this.type, {
    this.size = 28,
    this.color = InVogueColors.ink,
    this.playKey,
    super.key,
  }) : still = false;

  /// The static Phosphor glyph; never moves.
  const WeatherGlyph.still(
    this.type, {
    this.size = 22,
    this.color = InVogueColors.ink,
    super.key,
  }) : still = true,
       playKey = null;

  final WeatherGlyphType type;
  final double size;
  final Color color;

  /// Replays the loop when changed.
  final Object? playKey;

  /// Draws the static Phosphor glyph instead of the moving parts.
  final bool still;

  @override
  State<WeatherGlyph> createState() => _WeatherGlyphState();
}

class _WeatherGlyphState extends State<WeatherGlyph>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _loop;
  bool _canPlay = false;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(vsync: this, duration: widget.type.loop)
      ..addStatusListener(_onStatus);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final couldPlay = _canPlay;
    _canPlay =
        !widget.still &&
        !context.reduceMotion &&
        TickerMode.valuesOf(context).enabled;
    if (!_canPlay) {
      _rest();
    } else if (!couldPlay) {
      _play();
    }
  }

  @override
  void didUpdateWidget(WeatherGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.type != widget.type) _loop.duration = widget.type.loop;
    if (oldWidget.type != widget.type || oldWidget.playKey != widget.playKey) {
      _play();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _rest();
  }

  void _onStatus(AnimationStatus status) {
    if (status.isCompleted) _loop.value = 0;
  }

  void _play() {
    if (_canPlay) _loop.forward(from: 0);
  }

  void _rest() {
    _loop
      ..stop()
      ..value = 0;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size.square(widget.size),
      painter: WeatherGlyphPainter(
        type: widget.type,
        color: widget.color,
        still: widget.still,
        loop: _loop,
      ),
    ),
  );
}

/// Paints a [WeatherGlyph] at a point of its loop, on the 256-unit grid.
class WeatherGlyphPainter extends CustomPainter {
  WeatherGlyphPainter({
    required this.type,
    required this.color,
    required this.still,
    required this.loop,
  }) : super(repaint: loop);

  static const double grid = 256;

  final WeatherGlyphType type;
  final Color color;
  final bool still;

  /// Progress through [WeatherGlyphType.loop]; 0 is the resting frame.
  final Animation<double> loop;

  Duration get elapsed => type.loop * loop.value;

  /// 0 → 1 → 0 over a cycle, each half eased separately (CSS keyframes).
  static double swing(double phase) => phase < 0.5
      ? InVogueMotion.standard.transform(phase * 2)
      : 1 - InVogueMotion.standard.transform((phase - 0.5) * 2);

  /// Cycle phase of a part delayed by [delay]; null when it is at rest.
  double? _phase(Duration delay) {
    final local = elapsed - delay;
    final total = type.cycle * WeatherGlyphType.cycles;
    if (loop.value == 0 || local < Duration.zero || local >= total) return null;
    final cycle = type.cycle.inMicroseconds;
    return (local.inMicroseconds % cycle) / cycle;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / grid, size.height / grid);
    final fill = Paint()..color = color;
    if (still) {
      canvas.drawPath(SvgPath.parse(weatherStillPaths[type.specName]!), fill);
    } else {
      _paintMoving(canvas, fill);
    }
    canvas.restore();
  }

  void _paintMoving(Canvas canvas, Paint fill) {
    final phase = _phase(Duration.zero);
    final glyph = SvgPath.parse(weatherStillPaths[type.specName]!);
    switch (type) {
      case WeatherGlyphType.sun:
        final turn = phase == null ? 0.0 : swing(phase) * 12 * math.pi / 180;
        canvas
          ..translate(grid / 2, grid / 2)
          ..rotate(turn)
          ..translate(-grid / 2, -grid / 2)
          ..drawPath(glyph, fill);
      case WeatherGlyphType.cloudSun ||
          WeatherGlyphType.cloud ||
          WeatherGlyphType.cloudFog:
        canvas
          ..translate(phase == null ? 0 : swing(phase) * 18, 0)
          ..drawPath(glyph, fill);
      case WeatherGlyphType.wind:
        final k = phase == null ? 0.0 : swing(phase);
        canvas
          ..translate(k * 22, 0)
          ..drawPath(glyph, fill..color = _fade(lerpDouble(1, 0.55, k)!));
      case WeatherGlyphType.cloudLightning:
        canvas.drawPath(glyph, fill..color = _fade(_boltOpacity(phase)));
      case WeatherGlyphType.cloudRain:
        canvas.drawPath(SvgPath.parse(weatherCloudBodyPath), fill);
        final stroke = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round;
        for (var i = 0; i < weatherDrops.length; i++) {
          final p = _phase(type.stagger! * i);
          final (from, to) = weatherDrops[i];
          final shift = p == null ? Offset.zero : Offset(-12 * p, 36 * p);
          final opacity = p == null ? 1.0 : (p < 0.8 ? 1 - p / 0.8 : 0.0);
          canvas.drawLine(
            from + shift,
            to + shift,
            stroke..color = _fade(opacity),
          );
        }
      case WeatherGlyphType.cloudSnow:
        canvas.drawPath(SvgPath.parse(weatherCloudBodyPath), fill);
        for (var i = 0; i < weatherFlakes.length; i++) {
          final p = _phase(type.stagger! * i);
          final shift = p == null ? 0.0 : 36 * p;
          final opacity = p == null ? 1.0 : (p < 0.85 ? 1 - p / 0.85 : 0.0);
          canvas.drawCircle(
            weatherFlakes[i] + Offset(0, shift),
            10,
            Paint()..color = _fade(opacity),
          );
        }
    }
  }

  Color _fade(double opacity) => color.withValues(alpha: color.a * opacity);

  /// Full until 40% of the cycle, 35% at half, full again at the end.
  static double _boltOpacity(double? phase) {
    if (phase == null || phase <= 0.4) return 1;
    final ease = InVogueMotion.standard.transform;
    return phase < 0.5
        ? lerpDouble(1, 0.35, ease((phase - 0.4) / 0.1))!
        : lerpDouble(0.35, 1, ease((phase - 0.5) / 0.5))!;
  }

  @override
  bool shouldRepaint(WeatherGlyphPainter oldDelegate) =>
      oldDelegate.type != type ||
      oldDelegate.color != color ||
      oldDelegate.still != still ||
      oldDelegate.loop != loop;
}
