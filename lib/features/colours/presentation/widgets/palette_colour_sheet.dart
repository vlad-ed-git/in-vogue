import 'package:flutter/material.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/core/utils/context_ext.dart';
import 'package:in_vogue/features/colours/domain/services/colour_names.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// Which part of a palette a colour is in.
enum PaletteGroup {
  suits,
  neutrals,
  goEasy;

  String label(AppLocalizations l10n) => switch (this) {
    PaletteGroup.suits => l10n.coloursSuit,
    PaletteGroup.neutrals => l10n.coloursNeutrals,
    PaletteGroup.goEasy => l10n.coloursGoEasy,
  };

  /// How to wear a colour of this group.
  String tip(AppLocalizations l10n) => switch (this) {
    PaletteGroup.suits => l10n.tipSuits,
    PaletteGroup.neutrals => l10n.tipNeutrals,
    PaletteGroup.goEasy => l10n.tipGoEasy,
  };
}

/// The name of a palette colour as it is said: the nearest clothing colour.
String paletteColourName(AppLocalizations l10n, int argb) =>
    l10n.colourName(ColourNames.nameOf(argb));

/// A palette colour, large, with its name, its group and how to wear it.
Future<void> showPaletteColourSheet({
  required BuildContext context,
  required int argb,
  required PaletteGroup group,
}) => showInVogueSheet<void>(
  context: context,
  builder: (context) {
    final l10n = context.translated;
    return InVogueSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InVogueSheetHeader(
            title: paletteColourName(l10n, argb),
            subtitle: group.label(l10n),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Swatch(color: Color(argb), size: 64),
          ),
          const SizedBox(height: InVogueSpace.s4),
          Text(group.tip(l10n), style: InVogueType.body),
        ],
      ),
    );
  },
);
