import 'package:flutter/painting.dart';

/// Grid, control sizes, shape, strokes and opacities of
/// `design-spec/tokens.json`. Designed on a 390-point phone; the same rules
/// hold from 320 to 430 points.
abstract final class InVogueLayout {
  /// The width the spec is drawn at.
  static const double designWidth = 390;

  /// Left and right margin of every screen at [compactWidth] and wider.
  static const double pageMargin = 20;

  /// Margin on phones narrower than [compactWidth].
  static const double pageMarginCompact = 16;

  /// Below this width the page margin is [pageMarginCompact].
  static const double compactWidth = 360;

  /// Between grid columns, tiles and side-by-side photos.
  static const double gutter = 12;

  /// Columns across the content width.
  static const int columns = 6;

  /// Every line height and vertical gap is a multiple of this.
  static const double baseline = 4;

  /// Buttons, fields and the picks bar.
  static const double controlHeight = 52;

  /// A button inside a half-width column, such as Buy at {Brand}.
  static const double controlHeightCompact = 44;

  /// Smallest tap area on Android; iOS needs [targetMinIos].
  static const double targetMin = 48;

  /// Smallest tap area on iOS.
  static const double targetMinIos = 44;

  /// City and Your picks; back bars.
  static const double topBarHeight = 44;

  /// Home · Makeup · Settings, above the bottom safe area.
  static const double tabBarHeight = 50;

  /// Smallest height of the Home photo stage.
  static const double stageMin = 300;

  /// Text scale beyond which layouts stack: the weather line puts the
  /// condition under the numeral and tiles go two to a row. It is where
  /// display styles stop growing.
  static const double largeTextScale = 1.3;

  /// Every corner: photos, buttons, fields, tiles, chips and sheets.
  static const BorderRadius radiusNone = BorderRadius.zero;

  /// Colour swatches only: a garment's real colour as a dot.
  static const double radiusRound = 9999;

  /// Rules, secondary edges and swatch rings.
  static const double strokeHairline = 1;

  /// Selection and focus: active tab rule, selected photo, tab bar marker.
  static const double strokeSelect = 2;

  /// The user's own photo while their outfit is being made.
  static const double opacityWaiting = 0.28;

  /// Photos of pieces and outfits behind Go Pro on the free plan.
  static const double opacityLocked = 0.45;

  /// Photos in tiles and pickers keep a 4:5 frame.
  static const double portraitAspectRatio = 4 / 5;

  /// The page margin for a screen [width] points wide.
  static double pageMarginFor(double width) =>
      width < compactWidth ? pageMarginCompact : pageMargin;

  /// The width of [span] of the [columns] grid columns inside a content area
  /// [contentWidth] points wide (the screen less both page margins).
  static double columnSpan(double contentWidth, int span) {
    assert(span >= 1 && span <= columns, 'span must be 1 to $columns');
    final column = (contentWidth - gutter * (columns - 1)) / columns;
    return column * span + gutter * (span - 1);
  }
}
