import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/app/router/in_vogue_screens.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/core/domain/errors/failures.dart';
import 'package:in_vogue/features/home/presentation/bloc/home_bloc.dart';
import 'package:in_vogue/features/makeup/presentation/bloc/makeup_bloc.dart';
import 'package:in_vogue/features/outfits/domain/entities/day_outfit.dart';
import 'package:in_vogue/features/outfits/domain/entities/outfit.dart';
import 'package:in_vogue/features/weather/domain/entities/day_weather.dart';
import 'package:in_vogue/features/weather/domain/entities/warmth_band.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_class.dart';
import 'package:in_vogue/features/weather/domain/entities/weather_report.dart';

final _date = DateTime.utc(2026, 10, 18);
const _wet = WeatherClass(
  band: WarmthBand.cool,
  precipitation: Precipitation.wet,
  windy: false,
);
final _report = WeatherReport(
  day: ForecastDay.tomorrow,
  weather: DayWeather(
    date: _date,
    occasion: Occasion.goingOut,
    temperature: 12,
    feelsLike: 10,
    sky: Sky.rain,
  ),
  weatherClass: _wet,
  fetchedAt: DateTime.utc(2026, 10, 17, 9),
  isSaved: false,
);
final _outfit = DayOutfit(
  outfit: const Outfit(id: 'o1', signature: 'dress', pieces: [], passes: []),
  date: _date,
  occasion: Occasion.goingOut,
  cell: 'cool|wet|calm|going_out',
  picture: '/support/outfits/uid-1/dress.jpg',
);

HomeState _home(
  HomeDay day, {
  HomeStatus status = HomeStatus.ready,
  ForecastDay selected = ForecastDay.tomorrow,
}) => HomeState(
  status: status,
  selected: selected,
  days: {ForecastDay.tomorrow: day},
);

void main() {
  test('follows the outfit Home shows, with its occasion and weather', () {
    expect(
      makeupDayOf(
        _home(HomeDay(report: _report, outfit: OutfitShown(_outfit))),
      ),
      MakeupDay(
        day: ForecastDay.tomorrow,
        occasion: Occasion.goingOut,
        outfit: _outfit,
        weather: _wet,
      ),
    );
  });

  test('waits for an outfit Home is looking up or making', () {
    expect(makeupDayOf(_home(HomeDay(report: _report))).outfitPending, isTrue);
    expect(
      makeupDayOf(
        _home(HomeDay(report: _report, outfit: const OutfitMaking())),
      ).outfitPending,
      isTrue,
    );
    expect(
      makeupDayOf(
        _home(const HomeDay(), status: HomeStatus.loading),
      ).outfitPending,
      isTrue,
    );
  });

  test('has no outfit when Home could not make one or has no weather', () {
    for (final day in [
      HomeDay(report: _report, outfit: const OutfitFailed(NetworkFailure())),
      const HomeDay(weatherFailed: true),
    ]) {
      final makeup = makeupDayOf(_home(day));
      expect(makeup.outfit, isNull);
      expect(makeup.outfitPending, isFalse);
    }
    expect(
      makeupDayOf(
        _home(const HomeDay(), status: HomeStatus.failed),
      ).outfitPending,
      isFalse,
    );
  });

  test('follows the day Home shows, even one it has not loaded', () {
    final today = makeupDayOf(
      _home(
        HomeDay(report: _report, outfit: OutfitShown(_outfit)),
        selected: ForecastDay.today,
      ),
    );
    expect(today.day, ForecastDay.today);
    expect(today.outfit, isNull);
    expect(today.outfitPending, isTrue);
  });
}
