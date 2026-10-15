import 'package:flutter/painting.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';

/// The type roles of `design-spec/tokens.json`: Sofia Sans in two widths.
///
/// Sizes are logical points (dp). Line heights are exact CSS line boxes:
/// `height` is the line height divided by the size, with the leading shared
/// evenly above and below, as a browser does. Letter spacing is in points
/// (the spec's `em` times the size). Each weight is set both as `fontWeight`
/// (for the CJK fallback) and as the variable `wght` axis.
abstract final class InVogueType {
  /// Sofia Sans Extra Condensed: the few big things.
  static const displayFamily = 'Sofia Sans Extra Condensed';

  /// Sofia Sans: everything you read.
  static const textFamily = 'Sofia Sans';

  /// Chinese falls back to the platform CJK face; no CJK font is bundled.
  static const cjkFallback = [
    'PingFang SC',
    'Noto Sans CJK SC',
    'Noto Sans SC',
  ];

  /// Display styles grow with the system text size up to this factor.
  static const displayMaxScale = 1.3;

  /// Text styles grow with the system text size up to this factor.
  static const textMaxScale = 2.0;

  /// The degree sign beside a display numeral is Sofia Sans 200 at 86%.
  static const degreeScale = 0.86;

  /// Counts and folios ("2 / 6", "Your picks · 3") use tabular figures.
  static const tabularFigures = [FontFeature.tabularFigures()];

  // Display: Sofia Sans Extra Condensed. At most one above the fold.

  /// The temperature on Home: 84 / 64, light.
  static const numeral = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 84,
    height: 64 / 84,
    fontWeight: FontWeight.w300,
    fontVariations: [FontVariation('wght', 300)],
    letterSpacing: -0.84,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Widget temperature and makeup step numbers: 48 / 40, light.
  static const numeralSmall = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 48,
    height: 40 / 48,
    fontWeight: FontWeight.w300,
    fontVariations: [FontVariation('wght', 300)],
    letterSpacing: -0.48,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Welcome and the two Pro screens: 52 / 48, bold.
  static const headline = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 52,
    height: 48 / 52,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.52,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The one screen title: 40 / 38, bold.
  static const title = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 40,
    height: 38 / 40,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: -0.2,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Headings inside a screen: 26 / 28, bold.
  static const section = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 26,
    height: 28 / 26,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Today / Tomorrow and Before / After: 24 / 24. Inactive weight 500;
  /// see [tabActive].
  static const tab = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 24,
    height: 1,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 0,
    color: InVogueColors.graphite,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The selected tab: weight 700 in ink.
  static const tabActive = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 24,
    height: 1,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The Pro price, the only price in the app: 28 / 32, light.
  static const figure = TextStyle(
    fontFamily: displayFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 28,
    height: 32 / 28,
    fontWeight: FontWeight.w300,
    fontVariations: [FontVariation('wght', 300)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  // Text: Sofia Sans. Sentence case, flush left, ragged right.

  /// The line that matters in a block: 17 / 24, semibold.
  static const bodyStrong = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 17,
    height: 24 / 17,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Piece names, the city, setting names: 15 / 20, semibold.
  static const item = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Running text: 16 / 24, regular.
  static const body = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Secondary facts, usually in graphite: 14 / 20, regular.
  static const meta = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Button labels, flush left: 17 / 20, semibold.
  static const button = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 17,
    height: 20 / 17,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Text actions: 15 / 20, medium. Underlining belongs to the link widget.
  static const link = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 15,
    height: 20 / 15,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Kickers in capitals, three words at most: 12 / 16, bold, +10%.
  /// Capitals are applied by the widget, never written into the string.
  static const label = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 1.2,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Photo credits and the plan line, usually in graphite: 12 / 16.
  static const caption = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Tab bar labels: 14 / 16. Inactive weight 500; see [navActive].
  static const nav = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 14,
    height: 16 / 14,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
    letterSpacing: 0,
    color: InVogueColors.graphite,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The current tab: weight 700 in ink.
  static const navActive = TextStyle(
    fontFamily: textFamily,
    fontFamilyFallback: cjkFallback,
    fontSize: 14,
    height: 16 / 14,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 0,
    color: InVogueColors.ink,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// The degree sign set after a display [numeral] (for example
  /// [numeral] or [numeralSmall]): Sofia Sans at weight 200 and 86% of the
  /// figure's size, because the condensed "°" is a tall oval that reads as a
  /// raised zero. Letter spacing is inherited from the numeral.
  ///
  /// The tokens give the numerals absolute line heights (64 and 40 points),
  /// which the smaller sign keeps, exactly as in CSS. The home-screen widget
  /// sets its numerals with a relative line height instead; pass
  /// [relativeLineHeight] there so the sign scales it with its own size.
  static TextStyle degreeFor(
    TextStyle numeral, {
    bool relativeLineHeight = false,
  }) {
    final size = numeral.fontSize! * degreeScale;
    final multiplier = numeral.height ?? 1;
    return TextStyle(
      fontFamily: textFamily,
      fontSize: size,
      height: relativeLineHeight
          ? multiplier
          : numeral.fontSize! * multiplier / size,
      fontWeight: FontWeight.w200,
      fontVariations: const [FontVariation('wght', 200)],
      leadingDistribution: TextLeadingDistribution.even,
    );
  }
}
