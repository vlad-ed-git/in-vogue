import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/foundations/kicker.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';

/// A labelled, square 52-point text field. Its edge turns 2-point ink when
/// focused.
class InVogueTextField extends StatefulWidget {
  const InVogueTextField({
    required this.label,
    required this.controller,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.sentences,
    this.autofillHints,
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;

  @override
  State<InVogueTextField> createState() => _InVogueTextFieldState();
}

class _InVogueTextFieldState extends State<InVogueTextField> {
  final _node = FocusNode();

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _node.hasFocus;
    // One node: the label names the field.
    return MergeSemantics(
      child: Column(
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
                padding: const EdgeInsets.symmetric(
                  horizontal: InVogueSpace.s4,
                ),
                child: Center(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _node,
                    style: InVogueType.bodyStrong,
                    cursorColor: InVogueColors.ink,
                    cursorWidth: 2,
                    cursorHeight: 22,
                    textInputAction: widget.textInputAction,
                    textCapitalization: widget.textCapitalization,
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
      ),
    );
  }
}
