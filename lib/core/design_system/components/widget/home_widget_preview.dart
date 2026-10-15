import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/components/weather/weather_glyph.dart';
import 'package:in_vogue/core/design_system/foundations/kicker.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/foundations/temperature_text.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The home-screen widget sizes, in points.
enum HomeWidgetSize {
  large(Size(338, 354), slabWidth: 154, numeral: 150),
  medium(Size(338, 158), slabWidth: 206, numeral: 118),
  small(Size(158, 158), slabWidth: 158, numeral: 104);

  const HomeWidgetSize(
    this.size, {
    required this.slabWidth,
    required this.numeral,
  });

  final Size size;
  final double slabWidth;

  /// Temperature size.
  final double numeral;
}

/// A rendering of the home-screen widget: a Rouge weather slab beside a
/// full-height picture (none in [HomeWidgetSize.small]).
///
/// The picture is the first available of [flatLays], [waitingPhoto] and
/// [portrait]. Scales uniformly to [width] and ignores text scaling.
class HomeWidgetPreview extends StatelessWidget {
  const HomeWidgetPreview({
    required this.size,
    required this.kicker,
    required this.dateLine,
    required this.temperature,
    required this.condition,
    required this.glyph,
    required this.semanticLabel,
    this.feelsLike,
    this.portrait,
    this.flatLays = const [],
    this.waitingPhoto,
    this.width,
    this.onTap,
    super.key,
  });

  final HomeWidgetSize size;

  /// Day word, such as "Tomorrow".
  final String kicker;

  /// Such as "Thu 16 Oct · Workday", or the saved time when stale.
  final String dateLine;
  final int temperature;
  final String condition;
  final WeatherGlyphType glyph;

  /// Describes the whole widget.
  final String semanticLabel;

  /// Shown in [HomeWidgetSize.large] only.
  final int? feelsLike;
  final ImageProvider? portrait;

  /// Garment photos shown instead of the portrait: the first in medium, up
  /// to three stacked in large.
  final List<ImageProvider> flatLays;

  /// Shown faded under "Getting ready".
  final ImageProvider? waitingPhoto;

  /// Rendered width; the design size when null.
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final design = size.size;
    final renderWidth = width ?? design.width;
    Widget widget = SizedBox(
      width: renderWidth,
      height: design.height * renderWidth / design.width,
      child: FittedBox(
        child: SizedBox.fromSize(
          size: design,
          child: MediaQuery.withNoTextScaling(
            child: ClipRect(
              child: ColoredBox(
                color: InVogueColors.rouge,
                child: Stack(
                  children: [
                    if (size != HomeWidgetSize.small)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        right: 0,
                        width: design.width - size.slabWidth,
                        child: _Picture(widget: this),
                      ),
                    Positioned(
                      top: 0,
                      bottom: 0,
                      left: 0,
                      width: size.slabWidth,
                      child: _Slab(widget: this),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    widget = Semantics(
      label: semanticLabel,
      image: onTap == null,
      excludeSemantics: true,
      child: widget,
    );
    if (onTap == null) return widget;
    return Pressable(
      onTap: onTap,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      expandTapTarget: false,
      builder: (context, state) => widget,
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

  static const _conditionLarge = TextStyle(
    fontFamily: InVogueType.textFamily,
    fontSize: 15,
    height: 18 / 15,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
    letterSpacing: 0,
    color: InVogueColors.rose,
    leadingDistribution: TextLeadingDistribution.even,
  );

  TextStyle get _condition => switch (widget.size) {
    HomeWidgetSize.large => _conditionLarge,
    HomeWidgetSize.medium => _kicker.copyWith(
      fontSize: 13,
      height: 16 / 13,
      fontWeight: FontWeight.w600,
      fontVariations: const [FontVariation('wght', 600)],
      letterSpacing: 0,
    ),
    HomeWidgetSize.small => _date.copyWith(color: InVogueColors.rose),
  };

  EdgeInsets get _padding => switch (widget.size) {
    HomeWidgetSize.large => const EdgeInsets.fromLTRB(16, 18, 0, 18),
    _ => const EdgeInsets.fromLTRB(16, 14, 14, 13),
  };

  @override
  Widget build(BuildContext context) {
    // Shrinks only when the figures do not fit, such as 104° in large.
    final numeral = Transform.translate(
      offset: const Offset(-5, 0),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.bottomStart,
        child: TemperatureText(
          widget.temperature,
          style: InVogueType.numeral.copyWith(
            fontSize: widget.size.numeral,
            height: 0.74,
            letterSpacing: -0.025 * widget.size.numeral,
            color: InVogueColors.rose,
          ),
          relativeLineHeight: true,
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
    final glyph = WeatherGlyph.still(
      widget.glyph,
      size: 24,
      color: InVogueColors.rose,
    );
    final heading = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _WidgetKicker(widget.kicker),
        if (widget.size != HomeWidgetSize.small) ...[
          const SizedBox(height: 3),
          Text(widget.dateLine, style: _date),
        ],
      ],
    );
    final (Widget top, Widget bottom) = switch (widget.size) {
      HomeWidgetSize.large => (
        heading,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            numeral,
            const SizedBox(height: 18),
            glyph,
            const SizedBox(height: 6),
            Text(widget.condition, style: _condition),
            if (widget.feelsLike != null) ...[
              const SizedBox(height: 4),
              Text(
                context.translated.feelsLike(widget.feelsLike!),
                style: _date,
              ),
            ],
          ],
        ),
      ),
      HomeWidgetSize.medium => (
        _TopRow(heading: heading, glyph: glyph),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(child: numeral),
            const SizedBox(width: 12 - 5),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(widget.condition, style: _condition),
              ),
            ),
          ],
        ),
      ),
      HomeWidgetSize.small => (
        _TopRow(heading: heading, glyph: glyph),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            numeral,
            const SizedBox(height: 8),
            Text(widget.condition, style: _condition),
          ],
        ),
      ),
    };
    return Padding(
      padding: _padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [top, bottom],
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

class _TopRow extends StatelessWidget {
  const _TopRow({required this.heading, required this.glyph});

  final Widget heading;
  final Widget glyph;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: heading),
      const SizedBox(width: 8),
      glyph,
    ],
  );
}

class _Picture extends StatelessWidget {
  const _Picture({required this.widget});

  final HomeWidgetPreview widget;

  static Widget _cover(ImageProvider image) => Image(
    image: image,
    fit: BoxFit.cover,
    gaplessPlayback: true,
    excludeFromSemantics: true,
    errorBuilder: (context, error, stack) => const SizedBox.expand(),
  );

  @override
  Widget build(BuildContext context) {
    final flatLays = widget.flatLays;
    if (flatLays.isNotEmpty) {
      if (widget.size == HomeWidgetSize.medium) {
        return ColoredBox(
          color: InVogueColors.studio,
          child: _cover(flatLays.first),
        );
      }
      final pieces = flatLays.take(3).toList();
      return Column(
        children: [
          for (var i = 0; i < pieces.length; i++) ...[
            if (i > 0) const SizedBox(height: InVogueLayout.strokeSelect),
            Expanded(
              child: SizedBox.expand(
                child: ColoredBox(
                  color: InVogueColors.studio,
                  child: _cover(pieces[i]),
                ),
              ),
            ),
          ],
        ],
      );
    }
    if (widget.waitingPhoto != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: InVogueLayout.opacityWaiting,
            child: _cover(widget.waitingPhoto!),
          ),
          Center(
            child: Text(
              context.translated.widgetGettingReady,
              textAlign: TextAlign.center,
              style: _Slab._conditionLarge,
            ),
          ),
        ],
      );
    }
    return ColoredBox(
      color: InVogueColors.studio,
      child: widget.portrait == null
          ? const SizedBox.expand()
          : _cover(widget.portrait!),
    );
  }
}
