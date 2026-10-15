import 'package:flutter/animation.dart';

/// Durations and easings of `design-spec/tokens.json`. Fast and few: every
/// screen is complete with all of it switched off.
abstract final class InVogueMotion {
  /// Pressed colour on buttons and rows.
  static const press = Duration(milliseconds: 100);

  /// Heart fill, text crossfades, the old numeral leaving.
  static const quick = Duration(milliseconds: 160);

  /// Outfit crossfade, new numeral arriving, tab rule sliding. Also every
  /// crossfade that replaces a movement under reduced motion.
  static const base = Duration(milliseconds: 240);

  /// Sheets in.
  static const sheet = Duration(milliseconds: 280);

  /// Sheets out.
  static const sheetOut = Duration(milliseconds: 200);

  /// The check mark on You're on the list.
  static const draw = Duration(milliseconds: 600);

  /// The curtain reveal of a newly made outfit.
  static const reveal = Duration(milliseconds: 720);

  /// The new numeral starts this long after the old one leaves.
  static const rollDelay = Duration(milliseconds: 40);

  /// How far a rolling numeral travels, in points.
  static const double rollDistance = 14;

  /// How far a newly selected hero settles upward, in points.
  static const double settleDistance = 4;

  /// Anything that moves within the screen.
  static const Curve standard = Cubic(0.2, 0, 0, 1);

  /// Things arriving: sheets, the new numeral, the check stroke.
  static const Curve enter = Cubic(0.05, 0.7, 0.1, 1);

  /// Things leaving: sheets closing, the old numeral.
  static const Curve exit = Cubic(0.3, 0, 0.8, 0.15);

  /// The curtain reveal only.
  static const Curve curtain = Cubic(0.65, 0, 0.35, 1);
}
