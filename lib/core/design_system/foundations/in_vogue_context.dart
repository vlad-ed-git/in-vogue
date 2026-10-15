import 'package:flutter/material.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// Design-system queries on the ambient context.
extension InVogueContext on BuildContext {
  /// Whether the platform asks to reduce motion.
  bool get reduceMotion => MediaQuery.disableAnimationsOf(this);

  /// Text scaler for display styles, capped at 1.3.
  TextScaler get displayTextScaler => MediaQuery.textScalerOf(
    this,
  ).clamp(maxScaleFactor: InVogueType.displayMaxScale);

  /// Whether text is scaled beyond [InVogueLayout.largeTextScale].
  bool get isLargeText =>
      MediaQuery.textScalerOf(this).scale(1) > InVogueLayout.largeTextScale;

  /// Horizontal page margin for the screen width.
  double get pageMargin =>
      InVogueLayout.pageMarginFor(MediaQuery.sizeOf(this).width);

  /// Whether the theme platform is iOS or macOS.
  bool get isApplePlatform => switch (Theme.of(this).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => true,
    _ => false,
  };

  /// Minimum tap area: 44 on Apple platforms, 48 elsewhere.
  double get minTapTarget =>
      isApplePlatform ? InVogueLayout.targetMinIos : InVogueLayout.targetMin;
}
