import 'package:flutter/material.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// What the design system reads from the surroundings: motion, text size,
/// platform and screen width.
extension InVogueContext on BuildContext {
  /// The system asks for reduced motion (iOS Reduce Motion, Android Remove
  /// animations): movements become crossfades or nothing.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// Display styles grow with the system text size up to 1.3 times.
  TextScaler get displayTextScaler => MediaQuery.textScalerOf(
    this,
  ).clamp(maxScaleFactor: InVogueType.displayMaxScale);

  /// Text is large enough that layouts stack: the weather condition goes
  /// under the numeral and tiles go two to a row.
  bool get isLargeText =>
      MediaQuery.textScalerOf(this).scale(1) > InVogueLayout.largeTextScale;

  /// The left and right margin of the screen.
  double get pageMargin =>
      InVogueLayout.pageMarginFor(MediaQuery.sizeOf(this).width);

  /// iOS and macOS follow Apple's conventions (Photos, Apple first).
  bool get isApplePlatform => switch (Theme.of(this).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };

  /// The smallest tap area: 44 points on Apple platforms, 48 dp elsewhere.
  double get minTapTarget =>
      isApplePlatform ? InVogueLayout.targetMinIos : InVogueLayout.targetMin;
}
