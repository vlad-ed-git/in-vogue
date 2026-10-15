import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A [Stack] whose positioned children receive taps outside its bounds.
class OverflowHitStack extends Stack {
  const OverflowHitStack({super.key, super.children})
    : super(clipBehavior: Clip.none);

  @override
  RenderStack createRenderObject(BuildContext context) =>
      _RenderOverflowHitStack(
        alignment: alignment,
        textDirection: textDirection ?? Directionality.maybeOf(context),
        fit: fit,
        clipBehavior: clipBehavior,
      );
}

class _RenderOverflowHitStack extends RenderStack {
  _RenderOverflowHitStack({
    super.alignment,
    super.textDirection,
    super.fit,
    super.clipBehavior,
  });

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    // Children test their own bounds, wherever they are painted.
    if (hitTestChildren(result, position: position)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
