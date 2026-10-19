import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/catalog/data/models/catalog_outfit_model.dart';
import 'package:in_vogue/features/catalog/domain/entities/catalog_outfit.dart';
import 'package:in_vogue/features/colours/domain/entities/colour_reading.dart';
import 'package:in_vogue/features/stylist/domain/entities/recommendation.dart';
import 'package:in_vogue/features/stylist/domain/services/candidate_rules.dart';
import 'package:in_vogue/features/weather/domain/entities/day_bands.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/entities/hourly_weather.dart';

Object? _fixture(String name) => jsonDecode(
  utf8.decode(gzip.decode(File('test/fixtures/$name').readAsBytesSync())),
);

/// The curated catalog the app reads (scripts/export_catalog_fixture.py).
final List<CatalogOutfit> catalogFixture = () {
  final json = _fixture('catalog_v2.json.gz')! as Map<String, Object?>;
  return [
    for (final outfit in json['outfits']! as List<Object?>)
      CatalogOutfitModel.fromJson(outfit),
  ]..sort((a, b) => a.order.compareTo(b.order));
}();

/// A year of one city's weather, 07:00 to 23:00 each day
/// (scripts/fetch_weather_year.py).
class WeatherYear {
  WeatherYear._(this.name, this.from, this._hours, this._first, this._last);

  final String name;

  /// Its first day, at midnight UTC.
  final DateTime from;
  final Map<String, List<int>> _hours;
  final int _first;
  final int _last;

  int get _perDay => _last - _first + 1;

  int get days => _hours['feelsLike']!.length ~/ _perDay;

  /// The date of day [index].
  DateTime date(int index) => from.add(Duration(days: index));

  /// Day [index]'s hours, as the app's forecast holds them. The archive has
  /// no probability, so an hour with an amount is certain.
  Forecast forecast(int index) {
    final date = this.date(index);
    return Forecast(
      hours: [
        for (var hour = 0; hour < _perDay; hour++)
          _hour(
            date.add(Duration(hours: _first + hour)),
            index * _perDay + hour,
          ),
      ],
      utcOffset: Duration.zero,
      fetchedAt: date,
    );
  }

  HourlyWeather _hour(DateTime time, int at) {
    final precipitation = _hours['precipitation']![at] / 10;
    final snowfall = _hours['snowfall']![at] / 10;
    return HourlyWeather(
      time: time,
      temperature: _hours['feelsLike']![at] / 10,
      feelsLike: _hours['feelsLike']![at] / 10,
      precipitationProbability: precipitation > 0 || snowfall > 0 ? 100 : 0,
      precipitation: precipitation,
      snowfall: snowfall,
      weatherCode: _hours['code']![at],
      windGusts: _hours['gusts']![at].toDouble(),
    );
  }

  /// The day of [date].
  int indexOf(DateTime date) => date.difference(from).inDays;
}

/// Ten cities' year of weather, October 2025 to September 2026.
final List<WeatherYear> weatherYears = () {
  final json = _fixture('weather_year.json.gz')! as Map<String, Object?>;
  return [
    for (final city
        in (json['cities']! as List<Object?>).cast<Map<String, Object?>>())
      WeatherYear._(
        city['name']! as String,
        DateTime.parse('${city['from']}T00:00:00Z'),
        {
          for (final MapEntry(:key, :value)
              in (city['hours']! as Map<String, Object?>).entries)
            if (value is List) key: value.cast<int>(),
        },
        (city['hours']! as Map<String, Object?>)['first']! as int,
        (city['hours']! as Map<String, Object?>)['last']! as int,
      ),
  ];
}();

WeatherYear weatherIn(String city) =>
    weatherYears.firstWhere((year) => year.name == city);

/// What the recommender must never break (design §12): the occasion, the
/// colours, the coldest hours as worn, the warmest hours as worn or with the
/// layer off, no rain-shy piece in rain and no bare legs in snow, unless the
/// recommendation says it gave that rule up.
void expectFollowsRules(
  Recommendation recommendation, {
  required DayBands day,
  required Occasion occasion,
  ColourSeason? season,
  String? why,
}) {
  final outfit = recommendation.outfit;
  final reason = '${outfit.id} ${why ?? ''}';
  expect(outfit.occasions, contains(occasion), reason: reason);
  expect(outfit.weathers, contains(day.cold), reason: reason);
  if (season != null) expect(outfit.seasons, contains(season), reason: reason);
  if (!recommendation.relaxed.contains(Relaxation.warmHours)) {
    expect(
      day.warm == day.cold ||
          outfit.weathers.contains(day.warm) ||
          outfit.baseWeathers.contains(day.warm),
      isTrue,
      reason: '$reason misses the warmest hours',
    );
  }
  if (!recommendation.relaxed.contains(Relaxation.weather)) {
    if (day.rain) {
      expect(outfit.rain, isNot(RainFit.avoid), reason: '$reason in rain');
    }
    if (day.snow) {
      expect(
        CandidateRules.bareLegged(outfit),
        isFalse,
        reason: '$reason bare legs in snow',
      );
    }
  }
}
