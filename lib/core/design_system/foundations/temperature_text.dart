import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A temperature set as a display numeral: "54°".
///
/// The figures use the display face; the degree sign is Sofia Sans 200 at
/// 86% of the figure's size, because the condensed "°" reads as a raised
/// zero. Only the degree sign is shown, never the unit. Screen readers hear
/// "54 degrees". Display text grows with the system size up to 1.3 times.
class TemperatureText extends StatelessWidget {
  const TemperatureText(
    this.degrees, {
    this.style = InVogueType.numeral,
    this.relativeLineHeight = false,
    this.color,
    this.textScaler,
    super.key,
  });

  /// Whole degrees in the user's unit.
  final int degrees;

  /// [InVogueType.numeral], [InVogueType.numeralSmall] or a widget size.
  final TextStyle style;

  /// The style's line height is relative (the home-screen widget's 0.74).
  final bool relativeLineHeight;
  final Color? color;

  /// The text scale; the display scale (capped at 1.3) when null.
  final TextScaler? textScaler;

  /// "54", or "−3" with a true minus sign.
  static String figures(int degrees) =>
      degrees < 0 ? '−${-degrees}' : '$degrees';

  @override
  Widget build(BuildContext context) {
    final figureStyle = color == null ? style : style.copyWith(color: color);
    return Text.rich(
      TextSpan(
        text: figures(degrees),
        style: figureStyle,
        children: [
          TextSpan(
            text: '°',
            style: InVogueType.degreeFor(
              style,
              relativeLineHeight: relativeLineHeight,
            ),
          ),
        ],
      ),
      semanticsLabel: context.translated.temperatureSpoken(degrees),
      textScaler: textScaler ?? context.displayTextScaler,
      maxLines: 1,
      softWrap: false,
    );
  }
}
