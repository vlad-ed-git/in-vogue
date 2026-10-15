import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';

/// Text with an optional highlight behind it and an optional underline, both
/// placed as CSS places them.
///
/// The highlight covers each line's glyph box (ascent to descent) plus
/// [highlightOutset]; the underline sits [underlineOffset] below each
/// baseline. Flutter's own span background and decoration follow different
/// metrics.
class MarkedText extends StatelessWidget {
  const MarkedText(
    this.text, {
    required this.style,
    this.highlight = false,
    this.highlightColor = InVogueColors.accent,
    this.highlightOutset = const EdgeInsets.symmetric(horizontal: 4),
    this.underline = false,
    this.underlineColor,
    this.underlineThickness = InVogueLayout.strokeHairline,
    this.underlineOffset = 3,
    this.textScaler,
    this.maxLines,
    this.semanticsLabel,
    super.key,
  });

  final String text;
  final TextStyle style;

  /// Paints [highlightColor] behind the text.
  final bool highlight;
  final Color highlightColor;

  /// How far the highlight extends beyond each line's glyph box.
  final EdgeInsets highlightOutset;

  /// Underlines every line.
  final bool underline;

  /// Defaults to the text colour.
  final Color? underlineColor;
  final double underlineThickness;

  /// Distance from the baseline to the underline's top.
  final double underlineOffset;

  /// Defaults to the ambient text scaler.
  final TextScaler? textScaler;
  final int? maxLines;

  /// Read by screen readers instead of [text].
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return Semantics(
      label: semanticsLabel ?? text,
      excludeSemantics: true,
      child: _MarkedTextLeaf(
        text: TextSpan(text: text, style: effective),
        textDirection: Directionality.of(context),
        textScaler: textScaler ?? MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        maxLines: maxLines,
        highlightColor: highlight ? highlightColor : null,
        highlightOutset: highlightOutset,
        underlineColor: underline
            ? (underlineColor ?? effective.color ?? InVogueColors.ink)
            : null,
        underlineThickness: underlineThickness,
        underlineOffset: underlineOffset,
      ),
    );
  }
}

class _MarkedTextLeaf extends LeafRenderObjectWidget {
  const _MarkedTextLeaf({
    required this.text,
    required this.textDirection,
    required this.textScaler,
    required this.locale,
    required this.maxLines,
    required this.highlightColor,
    required this.highlightOutset,
    required this.underlineColor,
    required this.underlineThickness,
    required this.underlineOffset,
  });

  final TextSpan text;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final int? maxLines;
  final Color? highlightColor;
  final EdgeInsets highlightOutset;
  final Color? underlineColor;
  final double underlineThickness;
  final double underlineOffset;

  @override
  RenderMarkedText createRenderObject(BuildContext context) => RenderMarkedText(
    text: text,
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
    maxLines: maxLines,
    highlightColor: highlightColor,
    highlightOutset: highlightOutset,
    underlineColor: underlineColor,
    underlineThickness: underlineThickness,
    underlineOffset: underlineOffset,
  );

  @override
  void updateRenderObject(BuildContext context, RenderMarkedText renderObject) {
    renderObject
      ..text = text
      ..textDirection = textDirection
      ..textScaler = textScaler
      ..locale = locale
      ..maxLines = maxLines
      ..highlightColor = highlightColor
      ..highlightOutset = highlightOutset
      ..underlineColor = underlineColor
      ..underlineThickness = underlineThickness
      ..underlineOffset = underlineOffset;
  }
}

/// Lays out and paints [MarkedText].
class RenderMarkedText extends RenderBox {
  RenderMarkedText({
    required TextSpan text,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale? locale,
    required int? maxLines,
    required this._highlightColor,
    required this._highlightOutset,
    required this._underlineColor,
    required this._underlineThickness,
    required this._underlineOffset,
  }) : _painter = TextPainter(
         text: text,
         textDirection: textDirection,
         textScaler: textScaler,
         locale: locale,
         maxLines: maxLines,
       );

  final TextPainter _painter;

  set text(TextSpan value) {
    final comparison = _painter.text!.compareTo(value);
    if (comparison == RenderComparison.identical) return;
    _painter.text = value;
    if (comparison.index >= RenderComparison.layout.index) {
      markNeedsLayout();
    } else {
      markNeedsPaint();
    }
  }

  set textDirection(TextDirection value) {
    if (_painter.textDirection == value) return;
    _painter.textDirection = value;
    markNeedsLayout();
  }

  set textScaler(TextScaler value) {
    if (_painter.textScaler == value) return;
    _painter.textScaler = value;
    markNeedsLayout();
  }

  set locale(Locale? value) {
    if (_painter.locale == value) return;
    _painter.locale = value;
    markNeedsLayout();
  }

  set maxLines(int? value) {
    if (_painter.maxLines == value) return;
    _painter.maxLines = value;
    markNeedsLayout();
  }

  Color? _highlightColor;
  set highlightColor(Color? value) {
    if (_highlightColor == value) return;
    _highlightColor = value;
    markNeedsPaint();
  }

  EdgeInsets _highlightOutset;
  set highlightOutset(EdgeInsets value) {
    if (_highlightOutset == value) return;
    _highlightOutset = value;
    markNeedsPaint();
  }

  Color? _underlineColor;
  set underlineColor(Color? value) {
    if (_underlineColor == value) return;
    _underlineColor = value;
    markNeedsPaint();
  }

  double _underlineThickness;
  set underlineThickness(double value) {
    if (_underlineThickness == value) return;
    _underlineThickness = value;
    markNeedsPaint();
  }

  double _underlineOffset;
  set underlineOffset(double value) {
    if (_underlineOffset == value) return;
    _underlineOffset = value;
    markNeedsPaint();
  }

  /// Highlight rectangles, one per line fragment.
  List<Rect> get highlightRects {
    final length = _painter.plainText.length;
    if (_highlightColor == null || length == 0) return const [];
    return [
      for (final box in _painter.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: length),
        boxHeightStyle: ui.BoxHeightStyle.tight,
      ))
        Rect.fromLTRB(
          box.left - _highlightOutset.left,
          box.top - _highlightOutset.top,
          box.right + _highlightOutset.right,
          box.bottom + _highlightOutset.bottom,
        ),
    ];
  }

  /// Underline rectangles, one per line.
  List<Rect> get underlineRects {
    if (_underlineColor == null) return const [];
    return [
      for (final line in _painter.computeLineMetrics())
        if (line.width > 0)
          Rect.fromLTWH(
            line.left,
            line.baseline + _underlineOffset,
            line.width,
            _underlineThickness,
          ),
    ];
  }

  void _layout(double maxWidth) =>
      _painter.layout(maxWidth: maxWidth.isFinite ? maxWidth : double.infinity);

  @override
  double computeMinIntrinsicWidth(double height) {
    _layout(double.infinity);
    return _painter.minIntrinsicWidth;
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    _layout(double.infinity);
    return _painter.maxIntrinsicWidth;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    _layout(width);
    return _painter.height;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    _layout(constraints.maxWidth);
    return constraints.constrain(_painter.size);
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    _layout(constraints.maxWidth);
    return _painter.computeDistanceToActualBaseline(baseline);
  }

  @override
  void performLayout() {
    _layout(constraints.maxWidth);
    size = constraints.constrain(_painter.size);
  }

  @override
  bool hitTestSelf(Offset position) => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    _layout(constraints.maxWidth);
    final canvas = context.canvas;
    if (_highlightColor != null) {
      final paint = Paint()..color = _highlightColor!;
      for (final rect in highlightRects) {
        canvas.drawRect(rect.shift(offset), paint);
      }
    }
    _painter.paint(canvas, offset);
    if (_underlineColor != null) {
      final paint = Paint()..color = _underlineColor!;
      for (final rect in underlineRects) {
        canvas.drawRect(rect.shift(offset), paint);
      }
    }
  }

  @override
  void dispose() {
    _painter.dispose();
    super.dispose();
  }
}
