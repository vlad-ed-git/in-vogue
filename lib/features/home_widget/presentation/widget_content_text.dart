import 'dart:ui' show Locale;

import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/presentation/foundations/in_vogue_format.dart';
import 'package:in_vogue/core/presentation/foundations/kicker.dart';
import 'package:in_vogue/core/utils/occasion_l10n.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/features/weather/presentation/weather_text.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// The widget's words for [WidgetDay]s, in the person's language.
abstract final class WidgetContentText {
  static WidgetContent of({
    required List<WidgetDay> days,
    required ForecastDay preferred,
    required String? countryCode,
    required String? bodyPhoto,
    required AppLocalizations l10n,
    required SupportedLanguages language,
    required DateTime now,
  }) {
    final code = language.languageCode;
    return WidgetContent(
      preferred: preferred,
      savedLine: l10n.widgetSaved(
        l10n.savedAt(
          InVogueFormat.shortDate(now, code),
          InVogueFormat.time(now, code),
        ),
      ),
      days: [
        for (final day in days)
          _snapshot(
            day,
            TemperatureUnit.forCountry(countryCode),
            bodyPhoto,
            l10n,
            language,
          ),
      ],
    );
  }

  static WidgetSnapshot _snapshot(
    WidgetDay day,
    TemperatureUnit unit,
    String? bodyPhoto,
    AppLocalizations l10n,
    SupportedLanguages language,
  ) {
    final code = language.languageCode;
    final weather = day.report.weather;
    final temperature = unit.degrees(weather.temperature);
    final feelsLike = unit.degrees(weather.feelsLike);
    final condition = weather.condition(l10n, code);
    final outfit = day.outfit;
    String kicker(String word) =>
        Kicker.usesCapitals(Locale(code)) ? word.toUpperCase() : word;
    String spoken(String dayWord) {
      final said = l10n.weatherSpokenWithDay(
        dayWord,
        temperature,
        condition,
        feelsLike,
      );
      if (outfit == null) return l10n.widgetPreviewSpoken(said);
      return [said, ?outfit.reason?.of(language)].join(' ');
    }

    return WidgetSnapshot(
      date: weather.date,
      occasion: weather.occasion,
      today: kicker(l10n.today),
      tomorrow: kicker(l10n.tomorrow),
      dateLine:
          '${InVogueFormat.shortDate(weather.date, code)} · '
          '${weather.occasion.kicker(l10n)}',
      temperature: temperature,
      condition: condition,
      feelsLike: l10n.feelsLike(feelsLike),
      glyph: weather.sky.glyph.specName,
      picture: outfit?.picture,
      waitingPhoto: outfit == null ? bodyPhoto : null,
      gettingReady: l10n.widgetGettingReady,
      spokenToday: spoken(l10n.today),
      spokenTomorrow: spoken(l10n.tomorrow),
    );
  }
}
