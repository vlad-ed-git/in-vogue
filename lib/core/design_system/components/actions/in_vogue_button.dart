import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icon.dart';
import 'package:in_vogue/core/design_system/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/design_system/foundations/pressable.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/design_system/tokens/in_vogue_type.dart';

/// How a button ranks. At most one primary on a screen.
enum InVogueButtonKind {
  /// Rouge with a white label: the step forward (Use my location, Continue,
  /// Next, Proceed, Shop, Get my makeup, Go Pro).
  primary,

  /// Rose with an ink label: actions that repeat or step aside (Buy at
  /// {Brand}, Try again). Never without a label.
  secondary,
}

/// A button: square, 52 points tall and as wide as its column, with the
/// label flush left and an optional icon flush right. Pressing darkens the
/// fill over 100 ms; there is no ripple, lift or shadow. A disabled button
/// is studio grey with a graphite label, but prefer showing a button only
/// when it can work.
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
    super.key,
  }) : kind = InVogueButtonKind.secondary;

  /// Verb first, sentence case, never a number.
  final String label;

  /// Null disables the button.
  final VoidCallback? onPressed;
  final InVogueButtonKind kind;

  /// `arrowRight` moves on, `arrowUpRight` leaves the app, `image` opens the
  /// photo picker, `retry` tries again.
  final InVogueIcons? icon;

  /// The icon's colour when it differs from the label (the Rouge heart of
  /// Loved).
  final Color? iconColor;

  /// 44 points tall, for a half-width column such as Buy at {Brand}.
  final bool compact;

  /// A secondary button set inside a Rose notice: paper, so it shows.
  final bool onRose;
  final String? semanticLabel;
  final FocusNode? focusNode;
  final bool autofocus;

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
    // A label that wraps keeps the button's height while it can, exactly as
    // the spec's fixed-height CSS does, then grows rather than overflow.
    final padding = compact
        ? const EdgeInsetsDirectional.fromSTEB(14, 2, InVogueSpace.s3, 2)
        : const EdgeInsetsDirectional.fromSTEB(18, 2, InVogueSpace.s4, 2);
    return Pressable(
      onTap: onPressed,
      semanticLabel: semanticLabel,
      focusNode: focusNode,
      autofocus: autofocus,
      expandTapTarget: false,
      builder: (context, state) {
        final enabled = state.enabled;
        final color = !enabled
            ? InVogueColors.studio
            : (state.pressed ? pressedFill : fill);
        final foreground = enabled ? labelColor : InVogueColors.graphite;
        return AnimatedContainer(
          duration: InVogueMotion.press,
          curve: InVogueMotion.standard,
          color: color,
          constraints: BoxConstraints(
            minHeight: height,
            minWidth: double.infinity,
          ),
          padding: padding,
          alignment: AlignmentDirectional.centerStart,
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
                InVogueIcon(
                  icon!,
                  size: compact ? 18 : 22,
                  color: enabled ? (iconColor ?? foreground) : foreground,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
