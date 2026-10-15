import 'package:flutter/animation.dart';

/// Durations, distances and easing curves.
abstract final class InVogueMotion {
  /// Pressed state.
  static const press = Duration(milliseconds: 100);

  /// Small changes and exits.
  static const quick = Duration(milliseconds: 160);

  /// Standard transitions and reduced-motion crossfades.
  static const base = Duration(milliseconds: 240);

  /// Sheet entrance.
  static const sheet = Duration(milliseconds: 280);

  /// Sheet exit.
  static const sheetOut = Duration(milliseconds: 200);

  /// Drawn strokes.
  static const draw = Duration(milliseconds: 600);

  /// Curtain reveal.
  static const reveal = Duration(milliseconds: 720);

  /// Delay before a rolling numeral enters.
  static const rollDelay = Duration(milliseconds: 40);

  /// Travel of a rolling numeral, in points.
  static const double rollDistance = 14;

  /// Upward settle of a crossfading photo, in points.
  static const double settleDistance = 4;

  static const Curve standard = Cubic(0.2, 0, 0, 1);
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1);
  static const Curve exit = Cubic(0.3, 0, 0.8, 0.15);
  static const Curve curtain = Cubic(0.65, 0, 0.35, 1);
}
