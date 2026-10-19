import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';

/// Text with an optional Rose highlight behind it and an optional underline,
/// both placed as CSS places them.
///
/// The highlight covers each line's glyph box (ascent to descent) plus 4
/// points either side; the underline sits 3 points below each baseline.
/// Flutter's own span background and decoration follow different metrics.
class MarkedText extends StatelessWidget {
  const MarkedText(
    this.text, {
    required this.style,
    this.highlight = false,
    this.underline = false,
    super.key,
  });

  final String text;
  final TextStyle style;

  /// Paints the Rose highlight behind the text.
  final bool highlight;

  /// Underlines every line in the text colour.
  final bool underline;

  @override
  Widget build(BuildContext context) {
    final effective = DefaultTextStyle.of(context).style.merge(style);
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: _MarkedTextLeaf(
        text: TextSpan(text: text, style: effective),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        locale: Localizations.maybeLocaleOf(context),
        highlightColor: highlight ? InVogueColors.accent : null,
        underlineColor: underline
            ? (effective.color ?? InVogueColors.ink)
            : null,
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
    required this.highlightColor,
    required this.underlineColor,
  });

  final TextSpan text;
  final TextDirection textDirection;
  final TextScaler textScaler;
  final Locale? locale;
  final Color? highlightColor;
  final Color? underlineColor;

  @override
  RenderMarkedText createRenderObject(BuildContext context) => RenderMarkedText(
    text: text,
    textDirection: textDirection,
    textScaler: textScaler,
    locale: locale,
    highlightColor: highlightColor,
    underlineColor: underlineColor,
  );

  @override
  void updateRenderObject(BuildContext context, RenderMarkedText renderObject) {
    renderObject
      ..text = text
      ..textDirection = textDirection
      ..textScaler = textScaler
      ..locale = locale
      ..highlightColor = highlightColor
      ..underlineColor = underlineColor;
  }
}

/// Lays out and paints [MarkedText].
class RenderMarkedText extends RenderBox {
  RenderMarkedText({
    required TextSpan text,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required Locale? locale,
    required this._highlightColor,
    required this._underlineColor,
  }) : _painter = TextPainter(
         text: text,
         textDirection: textDirection,
         textScaler: textScaler,
         locale: locale,
       );

  /// How far the highlight extends beyond each line's glyph box.
  static const _highlightOutset = EdgeInsets.symmetric(horizontal: 4);

  /// Distance from the baseline to the underline's top.
  static const _underlineOffset = 3.0;

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

  Color? _highlightColor;
  set highlightColor(Color? value) {
    if (_highlightColor == value) return;
    _highlightColor = value;
    markNeedsPaint();
  }

  Color? _underlineColor;
  set underlineColor(Color? value) {
    if (_underlineColor == value) return;
    _underlineColor = value;
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
            InVogueLayout.strokeHairline,
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
