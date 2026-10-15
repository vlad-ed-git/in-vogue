import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';

/// Grows the tap area of a small control (a text link, a swatch, a heart) to
/// the platform minimum without changing its size, so it still sits exactly
/// where the grid puts it. A tap in the margin reaches the control's centre.
///
/// Like any hit testing, the larger area only works inside the parent's
/// bounds; place small controls with room around them, as the spec does.
class TapTarget extends SingleChildRenderObjectWidget {
  const TapTarget({super.key, this.minSize, super.child});

  /// The smallest tap area; the platform minimum when null.
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

  /// The area that answers taps, in local coordinates.
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
