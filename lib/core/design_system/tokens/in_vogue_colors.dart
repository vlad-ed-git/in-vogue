import 'package:flutter/painting.dart';

/// The colour tokens of `design-spec/tokens.json`.
///
/// In Vogue has one theme, Paper, on every phone and in every system setting.
/// Ink on white does the work; Rouge is the step forward and the loved heart;
/// Rose is the second voice. The clothes supply every other colour.
abstract final class InVogueColors {
  /// The background of every screen, bar and sheet.
  static const paper = Color(0xFFFFFFFF);

  /// Disabled fills only, so an inactive control never looks like Rose.
  static const studio = Color(0xFFEDEDEB);

  /// Text, icons and every kind of selection (18.4:1 on [paper]).
  static const ink = Color(0xFF141414);

  /// Secondary text (6.5:1 on [paper], 4.7:1 on [accent]).
  static const graphite = Color(0xFF5E5E5C);

  /// Decorative hairlines (1.3:1): never the only edge of a control.
  static const rule = Color(0xFFE3E3E0);

  /// Edges that must be seen (3.5:1): field borders, swatch rings, chips.
  static const line = Color(0xFF8A8A88);

  /// Rouge: primary buttons and the loved heart (9.5:1 on [paper]).
  static const signal = Color(0xFF8C0F1F);

  /// A primary button while pressed.
  static const signalPressed = Color(0xFF740C19);

  /// Label and icon on Rouge.
  static const onSignal = Color(0xFFFFFFFF);

  /// Rose: secondary buttons and soft surfaces (notices, empty slots, the
  /// highlighter). A light surface, so its words and icons carry the meaning.
  static const accent = Color(0xFFF7D3D8);

  /// A secondary button while pressed.
  static const accentPressed = Color(0xFFF0C4CB);

  /// Text and icons on Rose (13.4:1).
  static const onAccent = Color(0xFF141414);

  /// Blocking errors and Delete account. There is no error red: Rouge means
  /// act, so a problem is ink with an icon and plain words.
  static const alert = ink;

  /// Ink at 40% behind an open sheet.
  static const veil = Color(0x66141414);

  /// A phone's wallpaper behind widget previews only.
  static const wallpaper = Color(0xFF3D3D3B);

  /// House code: the logo square and the home-screen widget's slab.
  static const rouge = Color(0xFF8C0F1F);

  /// House code: the type on Rouge in the home-screen widget.
  static const rose = Color(0xFFF7D3D8);

  /// Secondary type on Rouge: the widget's date and feels-like (5.3:1).
  static const roseMuted = Color(0xFFE8AEB8);
}
