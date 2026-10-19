import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/weather/weather_glyph.dart';
import 'package:in_vogue/core/presentation/foundations/kicker.dart';
import 'package:in_vogue/core/presentation/foundations/temperature_text.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A rendering of the large home-screen widget: a Rouge weather slab beside
/// a full-height picture.
///
/// The picture is [waitingPhoto], faded under "Getting ready", or studio grey
/// without it. Scales uniformly to [width] and ignores text scaling.
class HomeWidgetPreview extends StatelessWidget {
  const HomeWidgetPreview({
    required this.kicker,
    required this.dateLine,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.glyph,
    required this.semanticLabel,
    this.waitingPhoto,
    this.width,
    super.key,
  });

  /// The widget's size, in points.
  static const size = Size(338, 354);

  /// The weather slab's width.
  static const slabWidth = 154.0;

  /// Temperature size.
  static const numeral = 150.0;

  /// Day word, such as "Tomorrow".
  final String kicker;

  /// Such as "Thu 16 Oct · Workday", or the saved time when stale.
  final String dateLine;
  final int temperature;
  final int feelsLike;
  final String condition;
  final WeatherGlyphType glyph;

  /// Describes the whole widget.
  final String semanticLabel;

  /// Shown faded under "Getting ready".
  final ImageProvider? waitingPhoto;

  /// Rendered width; the design size when null.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final renderWidth = width ?? size.width;
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        width: renderWidth,
        height: size.height * renderWidth / size.width,
        child: FittedBox(
          child: SizedBox.fromSize(
            size: size,
            child: MediaQuery.withNoTextScaling(
              child: ClipRect(
                child: ColoredBox(
                  color: InVogueColors.rouge,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: size.width - slabWidth,
                        child: _Picture(widget: this),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: slabWidth,
                        child: _Slab(widget: this),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slab extends StatelessWidget {
  const _Slab({required this.widget});

  final HomeWidgetPreview widget;

  static const _kicker = TextStyle(
    fontFamily: InVogueType.textFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w700,
    fontVariations: [FontVariation('wght', 700)],
    letterSpacing: 1.32,
    color: InVogueColors.rose,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const _date = TextStyle(
    fontFamily: InVogueType.textFamily,
    fontSize: 11,
    height: 14 / 11,
    fontWeight: FontWeight.w400,
    fontVariations: [FontVariation('wght', 400)],
    letterSpacing: 0,
    color: InVogueColors.roseMuted,
    leadingDistribution: TextLeadingDistribution.even,
  );

  static const _condition = TextStyle(
    fontFamily: InVogueType.textFamily,
    fontSize: 15,
    height: 18 / 15,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0,
    color: InVogueColors.rose,
    leadingDistribution: TextLeadingDistribution.even,
  );

  @override
  Widget build(BuildContext context) {
    // Shrinks only when the figures do not fit, such as 104°.
    final numeral = Transform.translate(
      offset: const Offset(-5, 0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.bottomStart,
        child: TemperatureText(
          widget.temperature,
          style: InVogueType.numeral.copyWith(
            fontSize: HomeWidgetPreview.numeral,
            height: 0.74,
            letterSpacing: -0.025 * HomeWidgetPreview.numeral,
            color: InVogueColors.rose,
          ),
          relativeLineHeight: true,
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 0, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _WidgetKicker(widget.kicker),
              const SizedBox(height: 3),
              Text(widget.dateLine, style: _date),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              numeral,
              const SizedBox(height: 18),
              WeatherGlyph.still(
                widget.glyph,
                size: 24,
                color: InVogueColors.rose,
              ),
              const SizedBox(height: 6),
              Text(widget.condition, style: _condition),
              const SizedBox(height: 4),
              Text(
                context.translated.feelsLike(widget.feelsLike),
                style: _date,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A kicker at the widget's size: 11 points with 12% tracking.
class _WidgetKicker extends StatelessWidget {
  const _WidgetKicker(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final capitals = Kicker.usesCapitals(Localizations.maybeLocaleOf(context));
    return Text(
      capitals ? text.toUpperCase() : text,
      semanticsLabel: text,
      style: _Slab._kicker.copyWith(letterSpacing: capitals ? 1.32 : 0),
    );
  }
}

class _Picture extends StatelessWidget {
  const _Picture({required this.widget});

  final HomeWidgetPreview widget;

  @override
  Widget build(BuildContext context) {
    final waitingPhoto = widget.waitingPhoto;
    if (waitingPhoto == null) {
      return const ColoredBox(
        color: InVogueColors.studio,
        child: SizedBox.expand(),
      );
    }
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(
          opacity: InVogueLayout.opacityWaiting,
          child: Image(
            image: waitingPhoto,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => const SizedBox.expand(),
          ),
        ),
        Center(
          child: Text(
            context.translated.widgetGettingReady,
            textAlign: TextAlign.center,
            style: _Slab._condition,
          ),
        ),
      ],
    );
  }
}
