import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/foundations/running_rule.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// Button fill style.
enum InVogueButtonKind {
  /// Rouge fill, white label.
  primary,

  /// Rose fill, ink label.
  secondary,
}

/// A full-width square button with a flush-left label and an optional
/// trailing icon. Darkens while pressed; studio grey when disabled; keeps
/// its colours and runs a [RunningRule] along its bottom while [busy].
class InVogueButton extends StatelessWidget {
  const InVogueButton({
    required this.label,
    required this.onPressed,
    this.kind = InVogueButtonKind.primary,
    this.icon,
    this.iconColor,
    this.compact = false,
    this.onRose = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.busy = false,
    super.key,
  });

  /// A Rouge primary button.
  const InVogueButton.primary({
    required this.label,
    required this.onPressed,
    this.icon = InVogueIcons.arrowRight,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.busy = false,
    super.key,
  }) : kind = InVogueButtonKind.primary,
       iconColor = null,
       compact = false,
       onRose = false;

  /// A Rose secondary button.
  const InVogueButton.secondary({
    required this.label,
    required this.onPressed,
    this.icon,
    this.iconColor,
    this.compact = false,
    this.onRose = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.busy = false,
    super.key,
  }) : kind = InVogueButtonKind.secondary;

  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final InVogueButtonKind kind;

  final IconData? icon;

  /// Icon colour when it differs from the label.
  final Color? iconColor;

  /// 44 points tall instead of 52.
  final bool compact;

  /// Paper fill instead of Rose, for Rose backgrounds.
  final bool onRose;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Working: taps do nothing and screen readers hear it loading.
  final bool busy;

  (Color fill, Color pressed, Color label) get _colors => switch (kind) {
    InVogueButtonKind.primary => (
      InVogueColors.signal,
      InVogueColors.signalPressed,
      InVogueColors.onSignal,
    ),
    InVogueButtonKind.secondary when onRose => (
      InVogueColors.paper,
      InVogueColors.accentPressed,
      InVogueColors.onAccent,
    ),
    InVogueButtonKind.secondary => (
      InVogueColors.accent,
      InVogueColors.accentPressed,
      InVogueColors.onAccent,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final (fill, pressedFill, labelColor) = _colors;
    final height = compact
        ? InVogueLayout.controlHeightCompact
        : InVogueLayout.controlHeight;
    // A wrapping label keeps the minimum height while it fits, then grows.
    final padding = compact
        ? const EdgeInsetsDirectional.fromSTEB(14, 2, InVogueSpace.s3, 2)
        : const EdgeInsetsDirectional.fromSTEB(18, 2, InVogueSpace.s4, 2);
    return Pressable(
      onTap: busy ? null : onPressed,
      semanticLabel: semanticLabel,
      semanticValue: busy ? context.translated.loading : null,
      focusNode: focusNode,
      autofocus: autofocus,
      expandTapTarget: false,
      builder: (context, state) {
        final enabled = busy || state.enabled;
        final color = !enabled
            ? InVogueColors.studio
            : (state.pressed ? pressedFill : fill);
        final foreground = enabled ? labelColor : InVogueColors.graphite;
        final button = AnimatedContainer(
          duration: InVogueMotion.press,
          curve: InVogueMotion.standard,
          color: color,
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: double.infinity,
          ),
          padding: padding,
          // The row centres the label; an alignment would also make the
          // button take all the height it is given.
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: InVogueType.button.copyWith(color: foreground),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: InVogueSpace.s3),
                Icon(
                  icon!,
                  size: compact ? 18 : 22,
                  color: enabled ? (iconColor ?? foreground) : foreground,
                ),
              ],
            ],
          ),
        );
        if (!busy) return button;
        return Stack(
          children: [
            button,
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: RunningRule(color: labelColor),
            ),
          ],
        );
      },
    );
  }
}
