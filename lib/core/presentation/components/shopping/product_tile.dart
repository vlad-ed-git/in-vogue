import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/love_toggle.dart';
import 'package:in_vogue/core/presentation/foundations/overflow_hit_stack.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/foundations/swatch.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A product: 4:5 photo, name with a love toggle, and colour dots.
class ProductTile extends StatelessWidget {
  const ProductTile({
    required this.photo,
    required this.name,
    required this.colours,
    required this.loved,
    required this.onLoveChanged,
    required this.onTap,
    super.key,
  });

  final ImageProvider? photo;
  final String name;

  /// The product's colours, shown as dots.
  final List<Color> colours;
  final bool loved;
  final ValueChanged<bool>? onLoveChanged;
  final VoidCallback? onTap;

  /// Colour dots shown before "+N".
  static const int maxDots = 4;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final dots = colours.take(maxDots).toList();
    final extra = colours.length - dots.length;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PhotoSlot(image: photo, showLoading: true),
        Padding(
          padding: const EdgeInsets.only(top: InVogueSpace.s2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(name, style: InVogueType.item)),
              const SizedBox(width: InVogueSpace.s1),
              const SizedBox(width: _heartFootprint, height: 20),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Semantics(
            label: l10n.colourCount(colours.length),
            excludeSemantics: true,
            child: Row(
              children: [
                for (final colour in dots) ...[
                  Swatch(color: colour),
                  const SizedBox(width: InVogueSpace.s1),
                ],
                if (extra > 0)
                  Text(
                    l10n.moreColours(extra),
                    style: InVogueType.caption.copyWith(
                      color: InVogueColors.graphite,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final photoHeight =
            constraints.maxWidth / InVogueLayout.portraitAspectRatio;
        return OverflowHitStack(
          children: [
            Pressable(
              onTap: onTap,
              semanticLabel: name,
              expandTapTarget: false,
              builder: (context, state) => content,
            ),
            // The heart's 44-point box starts at the footprint's left edge
            // and overhangs the row by 12 above, below and to the right.
            Positioned(
              left: constraints.maxWidth - _heartFootprint,
              top: photoHeight + InVogueSpace.s2 - _heartOverhang,
              child: LoveToggle(
                loved: loved,
                onChanged: onLoveChanged,
                pieceLabel: name,
              ),
            ),
          ],
        );
      },
    );
  }

  static const double _heartOverhang = 12;
  static const double _heartFootprint = LoveToggle.size - _heartOverhang;
}
