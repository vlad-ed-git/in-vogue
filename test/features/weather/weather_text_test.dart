import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/presentation/presentation.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/temperature_unit.dart';
import 'package:in_vogue/features/weather/presentation/weather_text.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

DayWeather _day({Sky sky = Sky.clear, WeatherEvent? event}) => DayWeather(
  date: DateTime.utc(2026, 10, 16),
  occasion: Occasion.work,
  temperature: 12.4,
  feelsLike: 9.6,
  sky: sky,
  event: event,
);

void main() {
  setUpAll(initializeDateFormatting);

  group('TemperatureUnit', () {
    test('uses Fahrenheit in the United States and Celsius elsewhere', () {
      expect(TemperatureUnit.forCountry('US'), TemperatureUnit.fahrenheit);
      expect(TemperatureUnit.forCountry('pr'), TemperatureUnit.fahrenheit);
      expect(TemperatureUnit.forCountry('GB'), TemperatureUnit.celsius);
      expect(TemperatureUnit.forCountry('CN'), TemperatureUnit.celsius);
      expect(TemperatureUnit.forCountry(null), TemperatureUnit.celsius);
    });

    test('converts from Celsius and rounds only at the end', () {
      expect(TemperatureUnit.celsius.degrees(12.4), 12);
      expect(TemperatureUnit.fahrenheit.degrees(12.4), 54);
      expect(TemperatureUnit.fahrenheit.degrees(-40), -40);
      expect(TemperatureUnit.celsius.degrees(-0.4), 0);
    });
  });

  test('draws each sky with its glyph', () {
    expect(Sky.clear.glyph, WeatherGlyphType.sun);
    expect(Sky.partlyCloudy.glyph, WeatherGlyphType.cloudSun);
    expect(Sky.cloudy.glyph, WeatherGlyphType.cloud);
    expect(Sky.fog.glyph, WeatherGlyphType.cloudFog);
    expect(Sky.rain.glyph, WeatherGlyphType.cloudRain);
    expect(Sky.snow.glyph, WeatherGlyphType.cloudSnow);
    expect(Sky.storm.glyph, WeatherGlyphType.cloudLightning);
    expect(Sky.wind.glyph, WeatherGlyphType.wind);
  });

  group('condition', () {
    final english = lookupAppLocalizations(const Locale('en'));
    final afternoon = DateTime.utc(2026, 10, 16, 14);

    test('names the sky on a dry, calm day, with nothing to highlight', () {
      expect(_day().condition(english, 'en'), 'Sunny');
      expect(
        _day(sky: Sky.partlyCloudy).condition(english, 'en'),
        'Partly cloudy',
      );
      expect(_day(sky: Sky.cloudy).condition(english, 'en'), 'Cloudy');
      expect(_day(sky: Sky.fog).condition(english, 'en'), 'Foggy');
      expect(_day().highlight, isFalse);
    });

    test('times what changes what to wear, and highlights it', () {
      final showers = _day(
        sky: Sky.rain,
        event: WeatherEvent(
          WeatherEventKind.showers,
          WeatherTiming.from,
          afternoon,
        ),
      );
      expect(showers.condition(english, 'en'), 'Showers after 2 pm');
      expect(showers.highlight, isTrue);
      expect(
        _day(
          event: WeatherEvent(
            WeatherEventKind.wind,
            WeatherTiming.until,
            DateTime.utc(2026, 10, 16, 11, 30),
          ),
        ).condition(english, 'en'),
        'Strong wind until 11:30 am',
      );
      expect(
        _day(
          event: const WeatherEvent(
            WeatherEventKind.snow,
            WeatherTiming.allDay,
          ),
        ).condition(english, 'en'),
        'Snow all day',
      );
    });

    test('speaks Spanish and Chinese', () {
      final rain = _day(
        sky: Sky.rain,
        event: WeatherEvent(
          WeatherEventKind.rain,
          WeatherTiming.from,
          afternoon,
        ),
      );
      expect(
        rain.condition(lookupAppLocalizations(const Locale('es')), 'es'),
        'Lluvia desde las 14:00',
      );
      expect(
        rain.condition(lookupAppLocalizations(const Locale('zh')), 'zh'),
        '14:00后有雨',
      );
    });
  });
}
