import 'dart:math' as math;

import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/entities/hourly_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';

/// Turns a forecast into one day's weather line for an occasion, from the
/// hours that occasion spends outdoors.
///
/// Thresholds follow the knowledge base's weather classes (weather.v1.json):
/// AMS rain rates, Beaufort wind and the app's feels-like bands.
abstract final class DayWeatherRules {
  /// First and last hour, inclusive, that [occasion] spends outdoors.
  static (int, int) window(Occasion occasion) => switch (occasion) {
    Occasion.work => (7, 19),
    Occasion.casual || Occasion.stayingIn => (9, 20),
    Occasion.goingOut => (18, 23),
  };

  /// Gusts, km/h, that change what to wear (Beaufort 6).
  static const windyGusts = 39.0;

  /// Gusts, km/h, that turn a dry day's glyph to wind.
  static const windGlyphGusts = 50.0;

  /// Snow is snow only when the window feels colder than this, °C.
  static const snowBelow = 14.0;

  /// [forecast]'s hours on [date] in [occasion]'s window.
  static List<HourlyWeather> _windowHours(
    Forecast forecast,
    DateTime date,
    Occasion occasion,
  ) {
    final (first, last) = window(occasion);
    return [
      for (final hour in forecast.hours)
        if (hour.time.year == date.year &&
            hour.time.month == date.month &&
            hour.time.day == date.day &&
            hour.time.hour >= first &&
            hour.time.hour <= last)
          hour,
    ];
  }

  /// The knowledge base's class of the window: the band of its coldest
  /// feels-like; snow only when that band is cool or cold, rain otherwise;
  /// drizzle counts as dry and gales as windy. Null when the forecast does
  /// not cover the window.
  static WeatherClass? classify(
    Forecast forecast, {
    required DateTime date,
    required Occasion occasion,
  }) {
    final hours = _windowHours(forecast, date, occasion);
    if (hours.isEmpty) return null;
    final coldest = hours.map((hour) => hour.feelsLike).reduce(math.min);
    final snowCanSettle = coldest < snowBelow;
    final snow = hours.any(_isSnow);
    return WeatherClass(
      band: WarmthBand.forFeelsLike(coldest),
      precipitation: snow && snowCanSettle
          ? Precipitation.snow
          : snow || hours.any(_isWet)
          ? Precipitation.wet
          : Precipitation.dry,
      windy: hours.any((hour) => hour.windGusts >= windyGusts),
    );
  }

  /// Null when the forecast does not cover the window.
  static DayWeather? summarize(
    Forecast forecast, {
    required DateTime date,
    required Occasion occasion,
  }) {
    final hours = _windowHours(forecast, date, occasion);
    if (hours.isEmpty) return null;
    final warmest = hours.reduce(
      (a, b) => b.temperature > a.temperature ? b : a,
    );
    final coldest = hours.map((hour) => hour.feelsLike).reduce(math.min);
    final snowCanSettle = coldest < snowBelow;
    final snow = [
      for (final hour in hours)
        if (snowCanSettle && _isSnow(hour)) hour,
    ];
    final wet = [
      for (final hour in hours)
        if (_isWet(hour) || (!snowCanSettle && _isSnow(hour))) hour,
    ];
    final damp = hours.where(_isDamp).toList();
    final gusty = [
      for (final hour in hours)
        if (hour.windGusts >= windyGusts) hour,
    ];
    final strongestGust = hours.map((hour) => hour.windGusts).reduce(math.max);

    final Sky sky;
    final WeatherEvent? event;
    if (snow.isNotEmpty) {
      sky = Sky.snow;
      event = _timed(WeatherEventKind.snow, snow, hours);
    } else if (wet.isNotEmpty) {
      final stormy = wet.any((hour) => _isStorm(hour.weatherCode));
      final showers =
          wet.where((hour) => _isShowers(hour.weatherCode)).length * 2 >
          wet.length;
      sky = stormy ? Sky.storm : Sky.rain;
      event = _timed(
        stormy
            ? WeatherEventKind.storm
            : showers
            ? WeatherEventKind.showers
            : WeatherEventKind.rain,
        wet,
        hours,
      );
    } else if (damp.isNotEmpty) {
      sky = Sky.rain;
      event = _timed(WeatherEventKind.drizzle, damp, hours);
    } else {
      sky = strongestGust >= windGlyphGusts ? Sky.wind : _skyOf(hours);
      event = gusty.isEmpty
          ? null
          : _timed(WeatherEventKind.wind, gusty, hours);
    }
    return DayWeather(
      date: date,
      occasion: occasion,
      temperature: warmest.temperature,
      feelsLike: warmest.feelsLike,
      sky: sky,
      event: event,
    );
  }

  static bool _isSnow(HourlyWeather hour) =>
      (hour.snowfall > 0 && hour.precipitationProbability >= 40) ||
      _inRange(hour.weatherCode, 71, 77) ||
      hour.weatherCode == 85 ||
      hour.weatherCode == 86;

  static bool _isWet(HourlyWeather hour) =>
      (hour.precipitation >= 0.5 && hour.precipitationProbability >= 50) ||
      _inRange(hour.weatherCode, 61, 67) ||
      _isShowers(hour.weatherCode) ||
      _isStorm(hour.weatherCode);

  static bool _isDamp(HourlyWeather hour) =>
      _inRange(hour.weatherCode, 51, 57) ||
      (hour.precipitation >= 0.1 &&
          hour.precipitation < 0.5 &&
          hour.precipitationProbability >= 50);

  static bool _isShowers(int code) => _inRange(code, 80, 82);

  static bool _isStorm(int code) => _inRange(code, 95, 99);

  static bool _inRange(int code, int low, int high) =>
      code >= low && code <= high;

  /// Times [during], a run of [window]'s hours. An hour's amounts fall in
  /// the hour before it, so a run starts an hour before its first hour.
  static WeatherEvent _timed(
    WeatherEventKind kind,
    List<HourlyWeather> during,
    List<HourlyWeather> window,
  ) {
    final starts = during.first.time.isAfter(window.first.time);
    final ends = during.last.time.isBefore(window.last.time);
    if (starts) {
      return WeatherEvent(
        kind,
        WeatherTiming.from,
        during.first.time.subtract(const Duration(hours: 1)),
      );
    }
    if (ends) return WeatherEvent(kind, WeatherTiming.until, during.last.time);
    return WeatherEvent(kind, WeatherTiming.allDay);
  }

  /// The sky of most hours; a tie goes to the cloudier sky.
  static Sky _skyOf(List<HourlyWeather> hours) {
    const order = [Sky.clear, Sky.partlyCloudy, Sky.cloudy, Sky.fog];
    final counts = <Sky, int>{};
    for (final hour in hours) {
      final sky = switch (hour.weatherCode) {
        0 => Sky.clear,
        1 || 2 => Sky.partlyCloudy,
        45 || 48 => Sky.fog,
        _ => Sky.cloudy,
      };
      counts[sky] = (counts[sky] ?? 0) + 1;
    }
    return order.reduce(
      (best, sky) => (counts[sky] ?? 0) >= (counts[best] ?? 0) ? sky : best,
    );
  }
}
