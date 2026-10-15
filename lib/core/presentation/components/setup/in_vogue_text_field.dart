import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/kicker.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';

/// A labelled, square 52-point text field. Its edge turns 2-point ink when
/// focused; an error shows below with a warning icon.
class InVogueTextField extends StatefulWidget {
  const InVogueTextField({
    required this.label,
    required this.controller,
    this.focusNode,
    this.error,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.sentences,
    this.keyboardType,
    this.autofillHints,
    this.autofocus = false,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? error;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool autofocus;

  @override
  State<InVogueTextField> createState() => _InVogueTextFieldState();
}

class _InVogueTextFieldState extends State<InVogueTextField> {
  FocusNode? _ownNode;

  FocusNode get _node => widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(InVogueTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final old = oldWidget.focusNode ?? _ownNode;
    if (old != _node) {
      old?.removeListener(_onFocus);
      _node.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasFocus;
    final field = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Kicker(widget.label),
        const SizedBox(height: InVogueSpace.s2),
        DecoratedBox(
          // Inset like the spec's box-shadow edge, so focus never moves text.
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: focused ? InVogueColors.ink : InVogueColors.line,
              width: focused
                  ? InVogueLayout.strokeSelect
                  : InVogueLayout.strokeHairline,
            ),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: InVogueLayout.controlHeight,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: InVogueSpace.s4),
              child: Center(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _node,
                  autofocus: widget.autofocus,
                  style: InVogueType.bodyStrong,
                  cursorColor: InVogueColors.ink,
                  cursorWidth: 2,
                  cursorHeight: 22,
                  textInputAction: widget.textInputAction,
                  textCapitalization: widget.textCapitalization,
                  keyboardType: widget.keyboardType,
                  autofillHints: widget.autofillHints,
                  onSubmitted: widget.onSubmitted,
                  // The field draws its own edge; no theme border applies.
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    filled: false,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    focusedErrorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // One node: the label names the field.
        MergeSemantics(child: field),
        if (widget.error != null) ...[
          const SizedBox(height: InVogueSpace.s2),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const Icon(
                  InVogueIcons.warning,
                  size: 20,
                  color: InVogueColors.alert,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.error!,
                    style: InVogueType.meta.copyWith(
                      color: InVogueColors.alert,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
