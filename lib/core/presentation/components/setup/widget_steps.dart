import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_context.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_icons.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_colors.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_layout.dart';
import 'package:in_vogue/core/presentation/tokens/in_vogue_type.dart';
import 'package:in_vogue/core/utils/context_ext.dart';

/// The three numbered steps for adding a home-screen widget on iPhone.
class WidgetSteps extends StatelessWidget {
  const WidgetSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final steps = [
      (l10n.widgetStepHold, InVogueIcons.handTap),
      (l10n.widgetStepPlus, InVogueIcons.plus),
      (l10n.widgetStepChoose, InVogueIcons.squaresFour),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < steps.length; i++)
          DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: InVogueColors.rule)),
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                top: InVogueLayout.strokeHairline + 18,
                bottom: 18,
              ),
              child: MergeSemantics(
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${i + 1}',
                        style: InVogueType.numeralSmall,
                        textScaler: context.displayTextScaler,
                      ),
                    ),
                    const SizedBox(width: InVogueLayout.gutter),
                    Expanded(
                      child: Text(steps[i].$1, style: InVogueType.bodyStrong),
                    ),
                    const SizedBox(width: InVogueLayout.gutter),
                    SizedBox(
                      width: 28,
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Icon(steps[i].$2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
