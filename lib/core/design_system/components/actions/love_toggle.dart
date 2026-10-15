import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A heart toggle: an ink outline, or a Rouge fill that pops once with a
/// light haptic when turned on.
class LoveToggle extends StatefulWidget {
  const LoveToggle({
    required this.loved,
    required this.onChanged,
    required this.pieceLabel,
    super.key,
  });

  /// Tap area size.
  static const double size = 44;

  /// Heart size.
  static const double glyphSize = 22;

  final bool loved;

  /// Called with the new state; null disables the heart.
  final ValueChanged<bool>? onChanged;

  /// Read as "Love {pieceLabel}".
  final String pieceLabel;

  @override
  State<LoveToggle> createState() => _LoveToggleState();
}

class _LoveToggleState extends State<LoveToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop;

  /// Up to 1.2 and back, each half eased separately (CSS keyframes).
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _pop = AnimationController(vsync: this, duration: InVogueMotion.quick);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1,
          end: 1.2,
        ).chain(CurveTween(curve: InVogueMotion.standard)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.2,
          end: 1,
        ).chain(CurveTween(curve: InVogueMotion.standard)),
        weight: 1,
      ),
    ]).animate(_pop);
  }

  @override
  void didUpdateWidget(LoveToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.loved) _pop.value = 0;
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _toggle() {
    final loved = !widget.loved;
    if (loved) {
      InVogueHaptic.light.play();
      if (!context.reduceMotion) _pop.forward(from: 0);
    }
    widget.onChanged?.call(loved);
  }

  @override
  Widget build(BuildContext context) => Pressable(
    onTap: widget.onChanged == null ? null : _toggle,
    button: true,
    toggled: widget.loved,
    semanticLabel: context.translated.loveSpoken(widget.pieceLabel),
    semanticValue: widget.loved ? context.translated.loved : null,
    excludeSemantics: true,
    builder: (context, state) => SizedBox.square(
      dimension: LoveToggle.size,
      child: Center(
        child: ScaleTransition(
          scale: _scale,
          child: InVogueIcon(
            widget.loved ? InVogueIcons.heartFill : InVogueIcons.heart,
            size: LoveToggle.glyphSize,
            color: widget.loved ? InVogueColors.signal : InVogueColors.ink,
          ),
        ),
      ),
    ),
  );
}
