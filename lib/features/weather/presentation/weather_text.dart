import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

/// The glyph of a [Sky].
extension SkyGlyph on Sky {
  WeatherGlyphType get glyph => switch (this) {
    Sky.clear => WeatherGlyphType.sun,
    Sky.partlyCloudy => WeatherGlyphType.cloudSun,
    Sky.cloudy => WeatherGlyphType.cloud,
    Sky.fog => WeatherGlyphType.cloudFog,
    Sky.rain => WeatherGlyphType.cloudRain,
    Sky.snow => WeatherGlyphType.cloudSnow,
    Sky.storm => WeatherGlyphType.cloudLightning,
    Sky.wind => WeatherGlyphType.wind,
  };
}

/// The weather line's words for a day.
extension DayWeatherText on DayWeather {
  /// Whether the condition is the phrase that changes what to wear.
  bool get highlight => event != null;

  /// "Showers after 3 pm", "Snow all day" or the sky, "Sunny".
  String condition(AppLocalizations l10n, String languageCode) {
    final event = this.event;
    if (event == null) return l10n.weatherSky(sky.name);
    final kind = event.kind.name;
    final at = event.at;
    return switch (event.timing) {
      WeatherTiming.allDay => l10n.weatherAllDay(kind),
      WeatherTiming.from => l10n.weatherFrom(
        kind,
        InVogueFormat.time(at!, languageCode),
      ),
      WeatherTiming.until => l10n.weatherUntil(
        kind,
        InVogueFormat.time(at!, languageCode),
      ),
    };
  }
}
