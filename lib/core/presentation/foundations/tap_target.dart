import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';

/// Extends [child]'s tap area to at least [minSize] without changing its
/// layout size. Taps outside the parent's bounds are still not received.
class TapTarget extends SingleChildRenderObjectWidget {
  const TapTarget({super.key, this.minSize, super.child});

  /// Defaults to the platform minimum.
  final double? minSize;

  @override
  RenderTapTarget createRenderObject(BuildContext context) =>
      RenderTapTarget(minSize ?? context.minTapTarget);

  @override
  void updateRenderObject(BuildContext context, RenderTapTarget renderObject) {
    renderObject.minSize = minSize ?? context.minTapTarget;
  }
}

/// The render object of [TapTarget].
class RenderTapTarget extends RenderProxyBox {
  RenderTapTarget(this._minSize);

  double _minSize;
  double get minSize => _minSize;
  set minSize(double value) {
    if (value == _minSize) return;
    _minSize = value;
  }

  /// The area that receives taps, in local coordinates.
  Rect get tapArea {
    final dx = math.max(0, (_minSize - size.width) / 2).toDouble();
    final dy = math.max(0, (_minSize - size.height) / 2).toDouble();
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!tapArea.contains(position)) return false;
    final inside = (Offset.zero & size).contains(position)
        ? position
        : size.center(Offset.zero);
    if (hitTestChildren(result, position: inside) || hitTestSelf(inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
