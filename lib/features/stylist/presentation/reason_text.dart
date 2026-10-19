import 'package:in_vogue/core/presentation/foundations/in_vogue_format.dart';
import 'package:in_vogue/features/colours/presentation/colours_text.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// A recommendation's one-line reason, in the person's language and the
/// place's unit.
extension OutfitReasonText on OutfitReason {
  String line(
    AppLocalizations l10n, {
    required TemperatureUnit unit,
    required String language,
  }) {
    final coldest = unit.degrees(this.coldest);
    final warmest = unit.degrees(this.warmest);
    String at(DateTime time) => InVogueFormat.time(time, language);
    final from = this.from;
    final line = switch (kind) {
      ReasonKind.noWeatherMatch => l10n.reasonNoWeatherMatch,
      ReasonKind.noSpan => l10n.reasonNoSpan(coldest, warmest),
      ReasonKind.layerOff => l10n.reasonLayerOff(
        coldest,
        at(coldestAt),
        warmest,
        at(warmestAt),
      ),
      ReasonKind.snow =>
        from == null ? l10n.reasonSnowAllDay : l10n.reasonSnowFrom(at(from)),
      ReasonKind.rain =>
        from == null ? l10n.reasonRainAllDay : l10n.reasonRainFrom(at(from)),
      ReasonKind.freezing => l10n.reasonFreezing(coldest),
      ReasonKind.wind =>
        from == null ? l10n.reasonWindAllDay : l10n.reasonWindFrom(at(from)),
      ReasonKind.home => l10n.reasonHome,
      ReasonKind.steady =>
        coldest == warmest
            ? l10n.reasonSteadyOne(coldest)
            : l10n.reasonSteady(coldest, warmest),
    };
    final season = this.season;
    return season == null ? line : l10n.reasonInSeason(line, season.name(l10n));
  }
}
