import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/components/actions/in_vogue_button.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/foundations/layout_blocks.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_space.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The Pro plan: name, line, four benefits, prices and a Go Pro button.
class ProOffer extends StatelessWidget {
  const ProOffer({required this.onGoPro, super.key});

  final VoidCallback onGoPro;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final benefits = [
      l10n.proBenefitDaily,
      l10n.proBenefitChoice,
      l10n.proBenefitCollection,
      l10n.proBenefitMakeup,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScreenTitle(l10n.proName, style: InVogueType.headline),
        const SizedBox(height: InVogueSpace.s3),
        Text(
          l10n.proLine,
          style: InVogueType.body.copyWith(color: InVogueColors.graphite),
        ),
        const SizedBox(height: InVogueSpace.s6),
        DecoratedBox(
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: InVogueColors.rule)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final benefit in benefits)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: InVogueColors.rule)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: InVogueLayout.strokeHairline,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 52 - InVogueLayout.strokeHairline,
                      ),
                      child: Row(
                        children: [
                          const Icon(InVogueIcons.check, size: 20),
                          const SizedBox(width: InVogueSpace.s3),
                          Expanded(
                            child: Text(benefit, style: InVogueType.bodyStrong),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: InVogueLayout.strokeHairline),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(l10n.proPrice, style: InVogueType.figure),
        const SizedBox(height: InVogueSpace.s6),
        InVogueButton.primary(label: l10n.goPro, onPressed: onGoPro),
      ],
    );
  }
}
