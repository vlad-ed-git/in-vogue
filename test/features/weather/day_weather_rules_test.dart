import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:in_vogue/features/weather/domain/services/day_weather_rules.dart';

import 'forecast_fixtures.dart';

final _day = DateTime.utc(2026, 10, 16);

DayWeather _summarize(Forecast forecast, {Occasion occasion = Occasion.work}) =>
    DayWeatherRules.summarize(forecast, date: _day, occasion: occasion)!;

void main() {
  test('reports the warmest hour of the window and how it feels then', () {
    final forecast = forecastWith({
      for (var hour = 0; hour < 24; hour++)
        hour: (h) => h.copyWith(temperature: 8, feelsLike: 5),
      15: (h) => h.copyWith(temperature: 12.4, feelsLike: 9.6),
      22: (h) => h.copyWith(temperature: 30, feelsLike: 30),
    });
    final weather = _summarize(forecast);
    expect(weather.temperature, 12.4);
    expect(weather.feelsLike, 9.6);
    expect(weather.date, _day);
    expect(weather.occasion, Occasion.work);
  });

  test('uses the evening for going out and the casual hours at home', () {
    final forecast = forecastWith({
      12: (h) => h.copyWith(temperature: 20, feelsLike: 20),
      21: (h) => h.copyWith(temperature: 16, feelsLike: 15),
    });
    expect(_summarize(forecast, occasion: Occasion.goingOut).temperature, 16);
    expect(_summarize(forecast, occasion: Occasion.stayingIn).temperature, 20);
  });

  group('a dry, calm day', () {
    test('has nothing to highlight and the sky as its glyph', () {
      expect(_summarize(forecastWith({})).event, isNull);
      expect(_summarize(forecastWith({})).sky, Sky.clear);
    });

    test('takes the sky of most of its hours', () {
      Forecast sky(int code) => forecastWith({
        for (var hour = 7; hour <= 16; hour++)
          hour: (h) => h.copyWith(weatherCode: code),
      });
      expect(_summarize(sky(2)).sky, Sky.partlyCloudy);
      expect(_summarize(sky(3)).sky, Sky.cloudy);
      expect(_summarize(sky(45)).sky, Sky.fog);
    });
  });

  group('rain', () {
    Forecast wet(Iterable<int> hours, {int code = 63}) => forecastWith({
      for (final hour in hours)
        hour: (h) => h.copyWith(
          precipitation: 1.2,
          precipitationProbability: 80,
          weatherCode: code,
        ),
    });

    test('starting in the day is timed from the hour it begins', () {
      final weather = _summarize(wet([15, 16, 17, 18, 19]));
      expect(weather.sky, Sky.rain);
      expect(
        weather.event,
        WeatherEvent(
          WeatherEventKind.rain,
          WeatherTiming.from,
          DateTime.utc(2026, 10, 16, 14),
        ),
      );
    });

    test('stopping in the day is timed to the hour it ends', () {
      expect(
        _summarize(wet([7, 8, 9, 10])).event,
        WeatherEvent(
          WeatherEventKind.rain,
          WeatherTiming.until,
          DateTime.utc(2026, 10, 16, 10),
        ),
      );
    });

    test('through the whole window is all day', () {
      expect(
        _summarize(wet([7, 12, 19])).event,
        const WeatherEvent(WeatherEventKind.rain, WeatherTiming.allDay),
      );
    });

    test('from showers codes is called showers', () {
      expect(
        _summarize(wet([16, 17], code: 81)).event?.kind,
        WeatherEventKind.showers,
      );
    });

    test('needs a likely, measurable amount unless the code says rain', () {
      final unlikely = forecastWith({
        15: (h) => h.copyWith(precipitation: 2, precipitationProbability: 30),
      });
      expect(_summarize(unlikely).event, isNull);
      final coded = forecastWith({15: (h) => h.copyWith(weatherCode: 61)});
      expect(_summarize(coded).event?.kind, WeatherEventKind.rain);
    });

    test('outside the window does not count', () {
      expect(_summarize(wet([21, 22])).event, isNull);
    });
  });

  test('light rain is drizzle', () {
    final damp = forecastWith({
      13: (h) => h.copyWith(weatherCode: 53),
      14: (h) => h.copyWith(precipitation: 0.3, precipitationProbability: 70),
    });
    final weather = _summarize(damp);
    expect(weather.event?.kind, WeatherEventKind.drizzle);
    expect(weather.sky, Sky.rain);
  });

  test('a storm wins over rain', () {
    final stormy = forecastWith({
      12: (h) => h.copyWith(weatherCode: 63, precipitation: 3),
      17: (h) => h.copyWith(weatherCode: 95, precipitation: 5),
    });
    final weather = _summarize(stormy);
    expect(weather.event?.kind, WeatherEventKind.storm);
    expect(weather.sky, Sky.storm);
  });

  group('snow', () {
    Forecast snowy({required double feelsLike}) => forecastWith({
      for (var hour = 7; hour <= 19; hour++)
        hour: (h) => h.copyWith(feelsLike: feelsLike, temperature: feelsLike),
      10: (h) => h.copyWith(
        snowfall: 0.4,
        precipitationProbability: 60,
        weatherCode: 73,
        feelsLike: feelsLike,
        temperature: feelsLike,
      ),
    });

    test('in the cold is snow', () {
      final weather = _summarize(snowy(feelsLike: -2));
      expect(weather.event?.kind, WeatherEventKind.snow);
      expect(weather.sky, Sky.snow);
    });

    test('above the cool band reads as rain', () {
      final weather = _summarize(snowy(feelsLike: 15));
      expect(weather.event?.kind, WeatherEventKind.rain);
      expect(weather.sky, Sky.rain);
    });
  });

  group('wind', () {
    Forecast gusty(double gusts, {int from = 17}) => forecastWith({
      for (var hour = from; hour <= 19; hour++)
        hour: (h) => h.copyWith(windGusts: gusts),
    });

    test('from 39 km/h is strong wind, timed', () {
      final weather = _summarize(gusty(42));
      expect(
        weather.event,
        WeatherEvent(
          WeatherEventKind.wind,
          WeatherTiming.from,
          DateTime.utc(2026, 10, 16, 16),
        ),
      );
      expect(weather.sky, Sky.clear);
    });

    test('takes the wind glyph from 50 km/h on a dry day', () {
      expect(_summarize(gusty(55)).sky, Sky.wind);
    });

    test('gives way to rain', () {
      final forecast = forecastWith({
        12: (h) => h.copyWith(windGusts: 60),
        16: (h) => h.copyWith(
          windGusts: 60,
          precipitation: 2,
          precipitationProbability: 90,
          weatherCode: 63,
        ),
      });
      final weather = _summarize(forecast);
      expect(weather.event?.kind, WeatherEventKind.rain);
      expect(weather.sky, Sky.rain);
    });
  });

  test('knows nothing about a day the forecast does not cover', () {
    expect(
      DayWeatherRules.summarize(
        forecastWith({}),
        date: DateTime.utc(2026, 10, 25),
        occasion: Occasion.work,
      ),
      isNull,
    );
  });

  group('the knowledge base class', () {
    WeatherClass classify(
      Forecast forecast, [
      Occasion occasion = Occasion.work,
    ]) => DayWeatherRules.classify(forecast, date: _day, occasion: occasion)!;

    test('takes the band of the coldest feels-like in the window', () {
      final forecast = forecastWith({
        7: (h) => h.copyWith(feelsLike: 7),
        14: (h) => h.copyWith(feelsLike: 22),
        // Outside the workday.
        23: (h) => h.copyWith(feelsLike: -3),
      });
      expect(classify(forecast).band, WarmthBand.cold);
      expect(classify(forecastWith({})).band, WarmthBand.mild);
    });

    test('keeps rain and wind together, which the weather line cannot', () {
      final forecast = forecastWith({
        12: (h) => h.copyWith(precipitation: 2, precipitationProbability: 80),
        16: (h) => h.copyWith(windGusts: 45),
      });
      expect(
        classify(forecast),
        const WeatherClass(
          band: WarmthBand.mild,
          precipitation: Precipitation.wet,
          windy: true,
        ),
      );
      expect(
        classify(forecast, Occasion.goingOut).cell(Occasion.goingOut),
        'mild|dry|calm|going_out',
      );
      expect(classify(forecast).cell(Occasion.work), 'mild|wet|windy|work');
    });

    test('counts drizzle as dry and gales as windy', () {
      expect(
        classify(
          forecastWith({12: (h) => h.copyWith(weatherCode: 53)}),
        ).precipitation,
        Precipitation.dry,
      );
      expect(
        classify(forecastWith({12: (h) => h.copyWith(windGusts: 80)})).windy,
        isTrue,
      );
      expect(
        classify(forecastWith({12: (h) => h.copyWith(windGusts: 38)})).windy,
        isFalse,
      );
    });

    test('has snow only when it is cool or cold, rain otherwise', () {
      Forecast snow(double feelsLike) => forecastWith({
        for (var hour = 7; hour <= 19; hour++)
          hour: (h) => h.copyWith(feelsLike: feelsLike),
        10: (h) => h.copyWith(feelsLike: feelsLike, weatherCode: 73),
      });
      expect(classify(snow(2)).precipitation, Precipitation.snow);
      expect(classify(snow(15)).precipitation, Precipitation.wet);
    });

    test('names its cell with the occasion\'s context', () {
      const weather = WeatherClass(
        band: WarmthBand.hot,
        precipitation: Precipitation.dry,
        windy: false,
      );
      expect(weather.cell(Occasion.casual), 'hot|dry|calm|casual');
      expect(weather.cell(Occasion.stayingIn), 'hot|dry|calm|staying_in');
    });
  });
}
