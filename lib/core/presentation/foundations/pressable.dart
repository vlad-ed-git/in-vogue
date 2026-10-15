import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_vogue/core/presentation/foundations/focus_ring.dart';
import 'package:in_vogue/core/presentation/foundations/tap_target.dart';

/// Haptic feedback kinds.
enum InVogueHaptic {
  /// No haptic.
  none,

  /// A selection tick.
  selection,

  /// A light impact.
  light,

  /// A medium impact.
  medium;

  /// Plays this haptic.
  Future<void> play() => switch (this) {
    InVogueHaptic.none => Future.value(),
    InVogueHaptic.selection => HapticFeedback.selectionClick(),
    InVogueHaptic.light => HapticFeedback.lightImpact(),
    InVogueHaptic.medium => HapticFeedback.mediumImpact(),
  };
}

/// The interaction state passed to a [Pressable] builder.
@immutable
class PressableState {
  const PressableState({
    required this.pressed,
    required this.focused,
    required this.enabled,
  });

  /// A pointer is down on the control.
  final bool pressed;

  /// Focus is highlighted on the control.
  final bool focused;

  /// [Pressable.onTap] is set.
  final bool enabled;
}

/// A tappable control without ink effects: reports its pressed and focus
/// state to [builder], activates on tap, Enter or Space, draws a focus ring
/// for keyboard focus, and forms one semantics node.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.onTap,
    required this.builder,
    this.semanticLabel,
    this.semanticValue,
    this.excludeSemantics = false,
    this.button = true,
    this.link = false,
    this.selected,
    this.toggled,
    this.inMutuallyExclusiveGroup = false,
    this.role,
    this.haptic = InVogueHaptic.none,
    this.expandTapTarget = true,
    this.focusNode,
    this.autofocus = false,
    super.key,
  });

  /// Called on tap or keyboard activation; null disables the control.
  final VoidCallback? onTap;

  final Widget Function(BuildContext context, PressableState state) builder;

  /// Screen-reader label.
  final String? semanticLabel;

  /// Screen-reader value, read after the label.
  final String? semanticValue;

  /// Hides the content's own semantics.
  final bool excludeSemantics;

  final bool button;

  final bool link;

  final bool? selected;

  final bool? toggled;

  final bool inMutuallyExclusiveGroup;

  final SemanticsRole? role;

  final InVogueHaptic haptic;

  /// Wraps the control in a [TapTarget].
  final bool expandTapTarget;

  final FocusNode? focusNode;
  final bool autofocus;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _focused = false;
  bool _hasFocus = false;
  FocusNode? _ownNode;

  bool get _enabled => widget.onTap != null;

  FocusNode get _node =>
      widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'Pressable'));

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(Pressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _pressed) _pressed = false;
  }

  void _activate() {
    if (!_enabled) return;
    widget.haptic.play();
    widget.onTap!();
  }

  void _setPressed(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final state = PressableState(
      pressed: _pressed,
      focused: _focused,
      enabled: _enabled,
    );
    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      excludeFromSemantics: true,
      onTapDown: _enabled ? (_) => _setPressed(true) : null,
      onTapUp: _enabled ? (_) => _setPressed(false) : null,
      onTapCancel: _enabled ? () => _setPressed(false) : null,
      onTap: _enabled ? _activate : null,
      child: FocusRing(
        visible: _focused,
        child: widget.builder(context, state),
      ),
    );
    child = Semantics(
      container: true,
      role: widget.role,
      button: widget.button && !widget.link && widget.role == null,
      link: widget.link,
      enabled: _enabled,
      selected: widget.selected,
      toggled: widget.toggled,
      inMutuallyExclusiveGroup: widget.inMutuallyExclusiveGroup ? true : null,
      // One node per control: the focus semantics live here, not in a
      // second node from the Focus widget below.
      focusable: _enabled ? true : null,
      focused: _enabled ? _hasFocus : null,
      onFocus: _enabled ? _node.requestFocus : null,
      label: widget.semanticLabel,
      value: widget.semanticValue,
      excludeSemantics: widget.excludeSemantics,
      onTap: _enabled ? _activate : null,
      child: FocusableActionDetector(
        enabled: _enabled,
        focusNode: _node,
        includeFocusSemantics: false,
        autofocus: widget.autofocus,
        mouseCursor: _enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onFocusChange: (value) {
          if (_hasFocus != value) setState(() => _hasFocus = value);
        },
        onShowFocusHighlight: (value) {
          if (_focused != value) setState(() => _focused = value);
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              _activate();
              return null;
            },
          ),
        },
        child: child,
      ),
    );
    // Outermost, so no smaller box rejects a tap in the grown area first.
    return widget.expandTapTarget ? TapTarget(child: child) : child;
  }
}
