import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// A season's words in the person's language.
extension ColourSeasonText on ColourSeason {
  String name(AppLocalizations l10n) => switch (this) {
    ColourSeason.lightSpring => l10n.seasonLightSpring,
    ColourSeason.trueSpring => l10n.seasonTrueSpring,
    ColourSeason.brightSpring => l10n.seasonBrightSpring,
    ColourSeason.lightSummer => l10n.seasonLightSummer,
    ColourSeason.trueSummer => l10n.seasonTrueSummer,
    ColourSeason.softSummer => l10n.seasonSoftSummer,
    ColourSeason.softAutumn => l10n.seasonSoftAutumn,
    ColourSeason.trueAutumn => l10n.seasonTrueAutumn,
    ColourSeason.darkAutumn => l10n.seasonDarkAutumn,
    ColourSeason.darkWinter => l10n.seasonDarkWinter,
    ColourSeason.trueWinter => l10n.seasonTrueWinter,
    ColourSeason.brightWinter => l10n.seasonBrightWinter,
  };

  /// The colours that suit the season, in a sentence.
  String advice(AppLocalizations l10n) => switch (this) {
    ColourSeason.lightSpring => l10n.adviceLightSpring,
    ColourSeason.trueSpring => l10n.adviceTrueSpring,
    ColourSeason.brightSpring => l10n.adviceBrightSpring,
    ColourSeason.lightSummer => l10n.adviceLightSummer,
    ColourSeason.trueSummer => l10n.adviceTrueSummer,
    ColourSeason.softSummer => l10n.adviceSoftSummer,
    ColourSeason.softAutumn => l10n.adviceSoftAutumn,
    ColourSeason.trueAutumn => l10n.adviceTrueAutumn,
    ColourSeason.darkAutumn => l10n.adviceDarkAutumn,
    ColourSeason.darkWinter => l10n.adviceDarkWinter,
    ColourSeason.trueWinter => l10n.adviceTrueWinter,
    ColourSeason.brightWinter => l10n.adviceBrightWinter,
  };
}

/// Why: the undertone, depth and contrast behind a reading.
extension ColourReadingText on ColourReading {
  String facts(AppLocalizations l10n) =>
      l10n.colourFacts(undertone.name, depth.name, contrast.name);
}
