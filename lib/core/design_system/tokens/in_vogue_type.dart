import 'package:flutter/painting.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';

/// Text styles.
///
/// Line heights split their leading evenly above and below, as CSS does.
/// Weights are set on both `fontWeight` and the variable `wght` axis.
abstract final class InVogueType {
  /// Display typeface.
  static const displayFamily = 'Sofia Sans Extra Condensed';

  /// Text typeface.
  static const textFamily = 'Sofia Sans';

  /// Platform CJK faces used for Chinese.
  static const cjkFallback = [
    'PingFang SC',
    'Noto Sans CJK SC',
    'Noto Sans SC',
  ];

  /// Maximum text scale of display styles.
  static const displayMaxScale = 1.3;

  /// Maximum text scale of text styles.
  static const textMaxScale = 2.0;

  /// Size of a degree sign relative to its numeral.
  static const degreeScale = 0.86;

  /// Fixed-width digits.
  static const tabularFigures = [FontFeature.tabularFigures()];

  /// 84 / 64, light.
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

  /// 48 / 40, light.
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

  /// 52 / 48, bold.
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

  /// 40 / 38, bold.
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

  /// 26 / 28, bold.
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

  /// 24 / 24, medium, graphite.
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

  /// [tab], bold, ink.
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

  /// 28 / 32, light.
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

  /// 17 / 24, semibold.
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

  /// 15 / 20, semibold.
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

  /// 16 / 24, regular.
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

  /// 14 / 20, regular.
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

  /// 17 / 20, semibold.
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

  /// 15 / 20, medium.
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

  /// 12 / 16, bold, 10% tracking; shown in capitals by `Kicker`.
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

  /// 12 / 16, regular.
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

  /// 14 / 16, medium, graphite.
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

  /// [nav], bold, ink.
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

  /// Style of a degree sign after [numeral]: the text face at weight 200 and
  /// 86% of the size.
  ///
  /// Keeps the numeral's absolute line height, as CSS does, unless
  /// [relativeLineHeight] is set.
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
