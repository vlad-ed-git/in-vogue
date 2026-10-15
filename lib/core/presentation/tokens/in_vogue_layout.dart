import 'package:flutter/painting.dart';

/// Grid, sizes, shape, strokes and opacities.
abstract final class InVogueLayout {
  /// Reference screen width.
  static const double designWidth = 390;

  /// Horizontal page margin from [compactWidth] up.
  static const double pageMargin = 20;

  /// Horizontal page margin below [compactWidth].
  static const double pageMarginCompact = 16;
  static const double compactWidth = 360;

  /// Space between grid columns.
  static const double gutter = 12;
  static const int columns = 6;
  static const double baseline = 4;

  /// Height of buttons and fields.
  static const double controlHeight = 52;

  /// Height of compact buttons.
  static const double controlHeightCompact = 44;

  /// Minimum tap area on Android.
  static const double targetMin = 48;

  /// Minimum tap area on iOS.
  static const double targetMinIos = 44;

  /// Height of top and back bars.
  static const double topBarHeight = 44;

  /// Height of the tab bar, without the safe area.
  static const double tabBarHeight = 50;

  /// Minimum photo stage height.
  static const double stageMin = 300;

  /// Text scale above which layouts stack.
  static const double largeTextScale = 1.3;

  /// Corner radius of everything but swatches.
  static const BorderRadius radiusNone = BorderRadius.zero;

  /// Corner radius of swatches.
  static const double radiusRound = 9999;

  /// Hairline width.
  static const double strokeHairline = 1;

  /// Selection and focus stroke width.
  static const double strokeSelect = 2;

  /// Opacity of a photo behind a waiting message.
  static const double opacityWaiting = 0.28;

  /// Opacity of a locked photo.
  static const double opacityLocked = 0.45;

  /// Width over height of portrait photos.
  static const double portraitAspectRatio = 4 / 5;

  /// Page margin for a screen [width].
  static double pageMarginFor(double width) =>
      width < compactWidth ? pageMarginCompact : pageMargin;

  /// Width of [span] grid columns in a content area [contentWidth] wide.
  static double columnSpan(double contentWidth, int span) {
    assert(span >= 1 && span <= columns, 'span must be 1 to $columns');
    final column = (contentWidth - gutter * (columns - 1)) / columns;
    return column * span + gutter * (span - 1);
  }
}
