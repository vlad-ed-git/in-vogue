import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/foundations/swatch.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A product row: photo, name, colour, material, and a Buy at {brand}
/// button, under a hairline.
///
/// When [onBuy] is null the product is shown as no longer available.
class ShopItem extends StatelessWidget {
  const ShopItem({
    required this.photo,
    required this.name,
    required this.colourName,
    required this.colour,
    required this.brand,
    required this.onBuy,
    this.material,
    super.key,
  });

  final ImageProvider? photo;
  final String name;
  final String colourName;
  final Color colour;
  final String brand;
  final VoidCallback? onBuy;

  /// Omitted when unknown.
  final String? material;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final meta = InVogueType.meta.copyWith(color: InVogueColors.graphite);
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: InVogueColors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: InVogueLayout.strokeHairline + InVogueSpace.s6,
          bottom: InVogueSpace.s6,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: PhotoSlot(
                    image: photo,
                    showLoading: true,
                    semanticLabel: l10n.catalogPhotoSpoken(name, colourName),
                  ),
                ),
              ),
              const SizedBox(width: InVogueLayout.gutter),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(name, style: InVogueType.item),
                    const SizedBox(height: InVogueSpace.s1),
                    Row(
                      children: [
                        Swatch(color: colour),
                        const SizedBox(width: 6),
                        Flexible(child: Text(colourName, style: meta)),
                      ],
                    ),
                    if (material != null) ...[
                      const SizedBox(height: InVogueSpace.s1),
                      Text(material!, style: meta),
                    ],
                    if (onBuy == null) ...[
                      const SizedBox(height: InVogueSpace.s1),
                      Text(l10n.noLongerAvailable(brand), style: meta),
                    ] else ...[
                      const Spacer(),
                      const SizedBox(height: InVogueSpace.s1),
                      InVogueButton.secondary(
                        label: l10n.buyAt(brand),
                        icon: InVogueIcons.arrowUpRight,
                        compact: true,
                        onPressed: onBuy,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
