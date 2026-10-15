import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A temperature such as "54°", with the degree sign in a lighter, smaller
/// text face. Read as "54 degrees".
class TemperatureText extends StatelessWidget {
  const TemperatureText(
    this.degrees, {
    this.style = InVogueType.numeral,
    this.relativeLineHeight = false,
    this.color,
    this.textScaler,
    super.key,
  });

  final int degrees;

  final TextStyle style;

  /// Scales the degree sign's line height with its own size.
  final bool relativeLineHeight;
  final Color? color;

  /// Defaults to the display text scaler.
  final TextScaler? textScaler;

  /// Digits with a true minus sign below zero.
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
