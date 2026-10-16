import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Reports its child's size after each layout that changes it.
class SizeReporter extends SingleChildRenderObjectWidget {
  const SizeReporter({required this.onSize, super.child, super.key});

  /// Called after the frame in which the size changed.
  final ValueChanged<Size> onSize;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderSizeReporter(onSize);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderSizeReporter renderObject,
  ) => renderObject.onSize = onSize;
}

/// The render object of a [SizeReporter].
class RenderSizeReporter extends RenderProxyBox {
  RenderSizeReporter(this.onSize);

  ValueChanged<Size> onSize;
  Size? _reported;

  @override
  void performLayout() {
    super.performLayout();
    if (size == _reported) return;
    final reported = _reported = size;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (attached) onSize(reported);
    });
  }
}
