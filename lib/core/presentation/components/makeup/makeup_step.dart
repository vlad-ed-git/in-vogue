import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/photo_slot.dart';
import 'package:in_vogue/core/presentation/foundations/pressable.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_motion.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// A numbered step with its title, instructions, product kind and a
/// 96-point picture, under a hairline.
///
/// Without a [picture] the step is pending: graphite text, an empty Rose
/// square and "Preparing". The picture fades in when it arrives.
class MakeupStep extends StatelessWidget {
  const MakeupStep({
    required this.number,
    required this.title,
    this.instructions,
    this.product,
    this.note,
    this.picture,
    this.onPictureTap,
    super.key,
  });

  final int number;
  final String title;
  final String? instructions;

  /// The kind of product, such as "Cream blush".
  final String? product;

  /// Joined to [product], such as "showers after 3 pm".
  final String? note;
  final ImageProvider? picture;
  final VoidCallback? onPictureTap;

  bool get pending => picture == null;

  static const double pictureSize = 96;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final textColor = pending ? InVogueColors.graphite : InVogueColors.ink;
    final productLine = [?product, ?note].join(' · ');
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: InVogueColors.rule)),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          top: InVogueLayout.strokeHairline + InVogueSpace.s6,
          bottom: InVogueSpace.s6,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '$number',
                  style: InVogueType.numeralSmall.copyWith(color: textColor),
                  textScaler: context.displayTextScaler,
                ),
              ),
            ),
            const SizedBox(width: InVogueLayout.gutter),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: InVogueType.item.copyWith(color: textColor),
                  ),
                  if (pending) ...[
                    const SizedBox(height: InVogueSpace.s1),
                    Text(
                      l10n.preparing,
                      style: InVogueType.meta.copyWith(color: textColor),
                    ),
                  ] else ...[
                    if (instructions != null) ...[
                      const SizedBox(height: InVogueSpace.s1),
                      Text(instructions!, style: InVogueType.body),
                    ],
                    if (productLine.isNotEmpty) ...[
                      const SizedBox(height: InVogueSpace.s1),
                      Text(
                        productLine,
                        style: InVogueType.meta.copyWith(
                          color: InVogueColors.graphite,
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            const SizedBox(width: InVogueLayout.gutter),
            SizedBox.square(
              dimension: pictureSize,
              child: Pressable(
                onTap: pending ? null : onPictureTap,
                semanticLabel: l10n.faceAfterStep(number),
                excludeSemantics: true,
                expandTapTarget: false,
                builder: (context, state) => AnimatedSwitcher(
                  duration: context.reduceMotion
                      ? Duration.zero
                      : InVogueMotion.base,
                  switchInCurve: InVogueMotion.standard,
                  child: PhotoSlot(
                    key: ValueKey(picture),
                    image: picture,
                    aspectRatio: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
