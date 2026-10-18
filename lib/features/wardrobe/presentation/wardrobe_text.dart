import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';
import 'package:in_vogue/features/wardrobe/domain/entities/wardrobe_outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// An outfit colour's name in the person's language.
extension OutfitColourText on OutfitColour {
  String label(AppLocalizations l10n) => switch (this) {
    OutfitColour.black => l10n.colourBlack,
    OutfitColour.white => l10n.colourWhite,
    OutfitColour.grey => l10n.colourGrey,
    OutfitColour.beige => l10n.colourBeige,
    OutfitColour.brown => l10n.colourBrown,
    OutfitColour.navy => l10n.colourNavy,
    OutfitColour.blue => l10n.colourBlue,
    OutfitColour.green => l10n.colourGreen,
    OutfitColour.red => l10n.colourRed,
    OutfitColour.pink => l10n.colourPink,
    OutfitColour.purple => l10n.colourPurple,
    OutfitColour.yellow => l10n.colourYellow,
    OutfitColour.orange => l10n.colourOrange,
    OutfitColour.mixed => l10n.colourMixed,
  };
}

/// A feels-like band's name, as on Home's Outfits chips.
extension WarmthBandText on WarmthBand {
  String label(AppLocalizations l10n) => switch (this) {
    WarmthBand.hot => l10n.weatherHot,
    WarmthBand.warm => l10n.weatherWarm,
    WarmthBand.mild => l10n.weatherMild,
    WarmthBand.cool => l10n.weatherCool,
    WarmthBand.cold => l10n.weatherCold,
  };
}

/// What an outfit suits, in words.
extension OutfitDetailsText on OutfitDetails {
  /// Its weather, warmest first, then rain.
  String weather(AppLocalizations l10n) => [
    for (final band in WarmthBand.values)
      if (bands.contains(band)) band.label(l10n),
    if (rain) l10n.weatherRain,
  ].join(' · ');

  String occasionList(AppLocalizations l10n) => [
    for (final occasion in Occasion.values)
      if (occasions.contains(occasion)) occasion.label(l10n),
  ].join(' · ');
}
