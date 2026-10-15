import 'dart:ui' show SemanticsRole;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_vogue/core/design_system/foundations/focus_ring.dart';
import 'package:in_vogue/core/design_system/foundations/tap_target.dart';

/// The haptics of `design-spec/guide/06-motion.md`. Nothing else buzzes.
enum InVogueHaptic {
  /// No haptic.
  none,

  /// A selection tick: the day switch, chips and outfit tiles.
  selection,

  /// A light impact: loving a piece.
  light,

  /// A medium impact: the Pro check finishing.
  medium;

  /// Plays this haptic.
  Future<void> play() => switch (this) {
    InVogueHaptic.none => Future.value(),
    InVogueHaptic.selection => HapticFeedback.selectionClick(),
    InVogueHaptic.light => HapticFeedback.lightImpact(),
    InVogueHaptic.medium => HapticFeedback.mediumImpact(),
  };
}

/// What a [Pressable] tells the widget it draws.
@immutable
class PressableState {
  const PressableState({
    required this.pressed,
    required this.focused,
    required this.enabled,
  });

  /// A finger or pointer is down on the control.
  final bool pressed;

  /// Keyboard or switch focus is on the control.
  final bool focused;

  /// The control can be used.
  final bool enabled;
}

/// The interaction every In Vogue control shares: no ripple, no lift, just
/// a pressed state the control paints itself; Enter and Space activate it;
/// keyboard focus draws the focus ring; small controls reach the platform's
/// minimum tap area; and screen readers hear what it is.
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

  /// Draws the control for its current [PressableState].
  final Widget Function(BuildContext context, PressableState state) builder;

  /// Replaces or joins the spoken label of the content.
  final String? semanticLabel;

  /// Spoken after the label, such as "Loved".
  final String? semanticValue;

  /// Speak only [semanticLabel], not the content's own text.
  final bool excludeSemantics;

  /// Screen readers call it a button.
  final bool button;

  /// Screen readers call it a link.
  final bool link;

  /// Selection state for selectable items (tabs, tiles).
  final bool? selected;

  /// On or off state for toggles (the heart, chips).
  final bool? toggled;

  /// One choice among several, such as a tab.
  final bool inMutuallyExclusiveGroup;

  /// A specific role, such as [SemanticsRole.tab].
  final SemanticsRole? role;

  /// Played when the control activates.
  final InVogueHaptic haptic;

  /// Grow the tap area to the platform minimum without changing layout.
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
