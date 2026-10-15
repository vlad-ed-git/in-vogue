import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/navigation/day_switch.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// Before | After tabs over a face photo, with an optional sentence below.
/// Shows After once [after] is available.
class BeforeAfter extends StatefulWidget {
  const BeforeAfter({
    required this.before,
    this.after,
    this.sentence,
    this.aspectRatio = InVogueLayout.portraitAspectRatio,
    super.key,
  });

  final ImageProvider before;
  final ImageProvider? after;
  final String? sentence;
  final double aspectRatio;

  @override
  State<BeforeAfter> createState() => _BeforeAfterState();
}

class _BeforeAfterState extends State<BeforeAfter> {
  late int _selected = widget.after == null ? 0 : 1;

  @override
  void didUpdateWidget(BeforeAfter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.after == null && widget.after != null) _selected = 1;
    if (widget.after == null) _selected = 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final showAfter = _selected == 1 && widget.after != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DaySwitch(
          labels: [l10n.before, l10n.after],
          selectedIndex: _selected,
          onSelected: (i) {
            if (i == 1 && widget.after == null) return;
            setState(() => _selected = i);
          },
        ),
        const SizedBox(height: InVogueSpace.s4),
        AnimatedSwitcher(
          duration: context.reduceMotion ? Duration.zero : InVogueMotion.base,
          switchInCurve: InVogueMotion.standard,
          switchOutCurve: InVogueMotion.standard,
          child: PhotoSlot(
            key: ValueKey(showAfter),
            image: showAfter ? widget.after : widget.before,
            aspectRatio: widget.aspectRatio,
            // CSS object-position: 50% 30%.
            alignment: const Alignment(0, -0.4),
            semanticLabel: showAfter ? l10n.faceWithLook : l10n.facePhotoSpoken,
          ),
        ),
        if (widget.sentence != null)
          Padding(
            padding: const EdgeInsets.only(top: InVogueSpace.s3),
            child: Text(widget.sentence!, style: InVogueType.body),
          ),
      ],
    );
  }
}
