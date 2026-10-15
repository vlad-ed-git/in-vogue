import 'package:flutter/painting.dart';

/// Colour tokens.
abstract final class InVogueColors {
  /// Background.
  static const paper = Color(0xFFFFFFFF);

  /// Disabled fill.
  static const studio = Color(0xFFEDEDEB);

  /// Text, icons and selection.
  static const ink = Color(0xFF141414);

  /// Secondary text.
  static const graphite = Color(0xFF5E5E5C);

  /// Decorative hairline.
  static const rule = Color(0xFFE3E3E0);

  /// Visible control edge.
  static const line = Color(0xFF8A8A88);

  /// Primary action fill (Rouge).
  static const signal = Color(0xFF8C0F1F);

  /// Pressed primary action fill.
  static const signalPressed = Color(0xFF740C19);

  /// Content on [signal].
  static const onSignal = Color(0xFFFFFFFF);

  /// Secondary action and soft surface fill (Rose).
  static const accent = Color(0xFFF7D3D8);

  /// Pressed secondary action fill.
  static const accentPressed = Color(0xFFF0C4CB);

  /// Content on [accent].
  static const onAccent = Color(0xFF141414);

  /// Errors and destructive actions; the same as [ink].
  static const alert = ink;

  /// Scrim behind sheets: ink at 40%.
  static const veil = Color(0x66141414);

  /// Stand-in for a phone wallpaper.
  static const wallpaper = Color(0xFF3D3D3B);

  /// Brand Rouge.
  static const rouge = Color(0xFF8C0F1F);

  /// Brand Rose.
  static const rose = Color(0xFFF7D3D8);

  /// Secondary text on [rouge].
  static const roseMuted = Color(0xFFE8AEB8);
}
