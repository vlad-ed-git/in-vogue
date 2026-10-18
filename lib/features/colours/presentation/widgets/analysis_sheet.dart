import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/colours/domain/services/colour_space.dart';
import 'package:in_vogue/features/colours/presentation/colours_text.dart';

/// The whole skin analysis: the colours read from the photo, the undertone,
/// depth and contrast with what each means, and the season they make.
Future<void> showAnalysisSheet({
  required BuildContext context,
  required ColourReading reading,
}) => showInVogueSheet<void>(
  context: context,
  builder: (context) => InVogueSheet(child: _Analysis(reading)),
);

class _Analysis extends StatelessWidget {
  const _Analysis(this.reading);

  final ColourReading reading;

  @override
  Widget build(BuildContext context) {
    final l10n = context.translated;
    final colours = reading.colours;
    final features = [
      (l10n.featureSkin, colours.skin),
      (l10n.featureHair, colours.hair),
      (l10n.featureBrows, colours.eyebrow),
      if (colours.eye case final eye?) (l10n.featureEyes, eye),
      (l10n.featureLips, colours.lip),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InVogueSheetHeader(title: l10n.analysisTitle),
        Kicker(l10n.analysisRead),
        const SizedBox(height: InVogueSpace.s3),
        Wrap(
          spacing: InVogueSpace.s4,
          runSpacing: InVogueSpace.s3,
          children: [
            for (final (name, hex) in features)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Swatch(
                    color: Color(
                      ColourSpace.argbOf(hex) ??
                          InVogueColors.studio.toARGB32(),
                    ),
                    size: Swatch.large,
                  ),
                  const SizedBox(height: InVogueSpace.s1),
                  Text(name, style: InVogueType.meta),
                ],
              ),
          ],
        ),
        if (!reading.clear) ...[
          const SizedBox(height: InVogueSpace.s4),
          Notice(icon: InVogueIcons.image, message: l10n.coloursUnclear),
        ],
        ..._measure(
          l10n.analysisUndertone,
          l10n.undertoneAbout(reading.undertone.name),
        ),
        ..._measure(l10n.analysisDepth, l10n.depthAbout(reading.depth.name)),
        ..._measure(
          l10n.analysisContrast,
          l10n.contrastAbout(reading.contrast.name),
        ),
        const SizedBox(height: InVogueSpace.s6),
        Kicker(l10n.yourSeason),
        const SizedBox(height: InVogueSpace.s2),
        Text(reading.season.name(l10n), style: InVogueType.section),
        const SizedBox(height: InVogueSpace.s2),
        Text(reading.season.advice(l10n), style: InVogueType.body),
        const SizedBox(height: InVogueSpace.s6),
        Text(
          l10n.analysisNote,
          style: InVogueType.meta.copyWith(color: InVogueColors.graphite),
        ),
      ],
    );
  }

  static List<Widget> _measure(String title, String about) => [
    const SizedBox(height: InVogueSpace.s6),
    Kicker(title),
    const SizedBox(height: InVogueSpace.s2),
    Text(about, style: InVogueType.body),
  ];
}
