import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/marked_text.dart';
import 'package:in_vogue/core/presentation/foundations/temperature_text.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// Temperature, condition with its glyph, and feels-like on one line.
///
/// Read by screen readers as one sentence. Stacks at large text sizes. New
/// values show at once; a ShiftSwitcher can move between them.
class WeatherLine extends StatelessWidget {
  const WeatherLine({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.glyph,
    this.highlight = false,
    this.dayLabel,
    this.playKey,
    super.key,
  });

  final int temperature;
  final int feelsLike;

  /// A short condition sentence, such as "Showers after 3 pm".
  final String condition;
  final WeatherGlyphType glyph;

  /// Sets [condition] on the Rose highlighter.
  final bool highlight;

  /// Spoken first, such as "Tomorrow".
  final String? dayLabel;

  /// Replays the glyph's loop when changed.
  final Object? playKey;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final spoken = dayLabel == null
        ? l10n.weatherSpoken(temperature, condition, feelsLike)
        : l10n.weatherSpokenWithDay(
            dayLabel!,
            temperature,
            condition,
            feelsLike,
          );
    // The figure sits 4 points into the margin so its stroke, not its box,
    // aligns with the text below.
    final numeral = Transform.translate(
      offset: const Offset(-4, 0),
      child: TemperatureText(temperature, style: InVogueType.numeral),
    );
    final details = _Details(
      condition: condition,
      glyph: glyph,
      feelsLike: feelsLike,
      highlight: highlight,
      playKey: playKey,
    );
    return Semantics(
      label: spoken,
      excludeSemantics: true,
      container: true,
      child: Padding(
        padding: const EdgeInsets.only(
          top: InVogueSpace.s4,
          bottom: InVogueSpace.s3,
        ),
        child: context.isLargeText
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  numeral,
                  const SizedBox(height: InVogueSpace.s2),
                  details,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  numeral,
                  // 16 apart once the figure's 4-point shift is counted.
                  const SizedBox(width: InVogueSpace.s4 - 4),
                  Expanded(child: details),
                ],
              ),
      ),
    );
  }
}

class _Details extends StatelessWidget {
  const _Details({
    required this.condition,
    required this.glyph,
    required this.feelsLike,
    required this.highlight,
    required this.playKey,
  });

  final String condition;
  final WeatherGlyphType glyph;
  final int feelsLike;
  final bool highlight;
  final Object? playKey;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Row(
        children: [
          Transform.translate(
            offset: const Offset(-2, 0),
            child: WeatherGlyph(glyph, playKey: playKey),
          ),
          const SizedBox(width: 6 - 2),
          Flexible(
            child: MarkedText(
              condition,
              style: InVogueType.bodyStrong,
              highlight: highlight,
            ),
          ),
        ],
      ),
      Text(
        context.translated.feelsLike(feelsLike),
        style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
      ),
    ],
  );
}
