import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_look.dart';
import 'package:in_vogue/features/makeup/domain/entities/makeup_recipe.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// The words of a makeup look.
extension MakeupLookText on MakeupLook {
  /// One sentence tying the look's colours to the outfit's.
  String sentence(AppLocalizations l10n) => l10n.lookSentence(
    l10n.cheekColour(switch (cheeks) {
      CheekColour.softPink => 'soft_pink',
      CheekColour.peach => 'peach',
      CheekColour.rose => 'rose',
      CheekColour.terracotta => 'terracotta',
    }),
    l10n.lipColour(switch (lips) {
      LipColour.nude => 'nude',
      LipColour.rosyNude => 'rosy_nude',
      LipColour.rose => 'rose',
      LipColour.terracotta => 'terracotta',
      LipColour.red => 'red',
      LipColour.berry => 'berry',
      LipColour.brick => 'brick',
    }),
    switch (palette) {
      OutfitPalette.warmNeutral => 'warm',
      OutfitPalette.coolNeutral => 'cool',
      OutfitPalette.mixedNeutral => 'mixed',
      OutfitPalette.colourful => 'colourful',
    },
  );
}

/// The words of a makeup step.
extension LookStepText on LookStep {
  /// The kinds of product in [language], as one line starting with a
  /// capital.
  String productLine(SupportedLanguages language) {
    final line = [
      for (final product in products) product.of(language),
    ].join(language == SupportedLanguages.chinese ? '、' : ', ');
    return line.isEmpty ? line : line[0].toUpperCase() + line.substring(1);
  }
}

/// "Five steps" for [count] steps.
String stepCount(AppLocalizations l10n, int count) =>
    l10n.makeupStepCount(switch (count) {
      3 => 'three',
      4 => 'four',
      5 => 'five',
      6 => 'six',
      _ => 'other',
    });
