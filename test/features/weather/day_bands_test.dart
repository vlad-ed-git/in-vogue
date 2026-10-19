import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/weather/domain/entities/forecast.dart';
import 'package:in_vogue/features/weather/domain/entities/hourly_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/services/day_weather_rules.dart';

final _date = DateTime.utc(2026, 9, 3);

/// A day of hours, 00:00 to 23:00, feeling like [feelsLike] at each hour
/// unless [at] says otherwise.
Forecast _day(
  double feelsLike, {
  Map<int, double> at = const {},
  Map<int, double> rain = const {},
  Map<int, int> codes = const {},
  Map<int, double> snow = const {},
  Map<int, double> gusts = const {},
}) => Forecast(
  hours: [
    for (var hour = 0; hour < 24; hour++)
      HourlyWeather(
        time: _date.add(Duration(hours: hour)),
        temperature: at[hour] ?? feelsLike,
        feelsLike: at[hour] ?? feelsLike,
        precipitationProbability: rain.containsKey(hour) ? 80 : 0,
        precipitation: rain[hour] ?? 0,
        snowfall: snow[hour] ?? 0,
        weatherCode: codes[hour] ?? 1,
        windGusts: gusts[hour] ?? 10,
      ),
  ],
  utcOffset: Duration.zero,
  fetchedAt: _date,
);

void main() {
  test('a swing day: the coldest and warmest hours of the window', () {
    // Denver, September 3: 13 °C at 7, 31 °C by 3 pm.
    final day = DayWeatherRules.bands(
      _day(20, at: {6: 5, 7: 13, 15: 31, 21: 35}),
      date: _date,
      occasion: Occasion.work,
    )!;
    expect((day.cold, day.warm), (WarmthBand.cool, WarmthBand.hot));
    expect((day.coldest, day.coldestAt.hour), (13, 7));
    expect((day.warmest, day.warmestAt.hour), (31, 15));
    expect(day.span, [
      WarmthBand.hot,
      WarmthBand.warm,
      WarmthBand.mild,
      WarmthBand.cool,
    ]);
    expect(day.position, closeTo(5 / 6, 1e-9));
    expect(
      (day.rain, day.snow, day.windy, day.indoors),
      (false, false, false, false),
    );
  });

  test('rain, snow and strong wind, each from the hour it starts', () {
    final wet = DayWeatherRules.bands(
      _day(10, rain: {16: 0.6}, gusts: {12: 45}),
      date: _date,
      occasion: Occasion.work,
    )!;
    expect(wet.rainFrom!.hour, 15);
    expect(wet.windFrom!.hour, 11);
    final drizzle = DayWeatherRules.bands(
      _day(10, rain: {16: 0.2}, codes: {16: 53}),
      date: _date,
      occasion: Occasion.work,
    )!;
    expect(drizzle.rain, isFalse);
    final snowy = DayWeatherRules.bands(
      _day(-3, snow: {10: 1.2}, codes: {10: 73}),
      date: _date,
      occasion: Occasion.work,
    )!;
    expect((snowy.snowFrom!.hour, snowy.rain), (9, false));
    expect(snowy.cold, WarmthBand.freezing);
  });

  test('snow that can’t settle counts as rain', () {
    final day = DayWeatherRules.bands(
      _day(16, codes: {10: 71}),
      date: _date,
      occasion: Occasion.casual,
    )!;
    expect((day.snow, day.rain), (false, true));
  });

  test('each occasion reads its own hours', () {
    final forecast = _day(15, at: {7: 2, 22: -1});
    expect(
      DayWeatherRules.bands(
        forecast,
        date: _date,
        occasion: Occasion.work,
      )!.cold,
      WarmthBand.cold,
    );
    expect(
      DayWeatherRules.bands(
        forecast,
        date: _date,
        occasion: Occasion.casual,
      )!.cold,
      WarmthBand.mild,
    );
    expect(
      DayWeatherRules.bands(
        forecast,
        date: _date,
        occasion: Occasion.goingOut,
      )!.cold,
      WarmthBand.freezing,
    );
  });

  test('a day at home is one band from the mean, between Cool and Warm', () {
    final hot = DayWeatherRules.bands(
      _day(33, rain: {12: 4}),
      date: _date,
      occasion: Occasion.stayingIn,
    )!;
    expect(
      (hot.cold, hot.warm, hot.indoors),
      (WarmthBand.warm, WarmthBand.warm, true),
    );
    expect(hot.rain, isFalse);
    final freezing = DayWeatherRules.bands(
      _day(-20),
      date: _date,
      occasion: Occasion.stayingIn,
    )!;
    expect((freezing.cold, freezing.warm), (WarmthBand.cool, WarmthBand.cool));
    expect(freezing.position, 0);
  });

  test('none when the forecast does not cover the day', () {
    expect(
      DayWeatherRules.bands(
        _day(15),
        date: _date.add(const Duration(days: 1)),
        occasion: Occasion.work,
      ),
      isNull,
    );
  });
}
