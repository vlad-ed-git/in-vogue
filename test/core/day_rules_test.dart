import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/occasion.dart';

void main() {
  group('ForecastDay.shownAt', () {
    ForecastDay at(int hour, [int minute = 0]) =>
        ForecastDay.shownAt(DateTime.utc(2026, 10, 15, hour, minute));

    test('shows today from 06:00 to 08:59', () {
      expect(at(6), ForecastDay.today);
      expect(at(7, 30), ForecastDay.today);
      expect(at(8, 59), ForecastDay.today);
    });

    test('shows tomorrow the rest of the day and night', () {
      expect(at(5, 59), ForecastDay.tomorrow);
      expect(at(9), ForecastDay.tomorrow);
      expect(at(18), ForecastDay.tomorrow);
      expect(at(23, 59), ForecastDay.tomorrow);
      expect(at(0, 30), ForecastDay.tomorrow);
    });
  });

  test('gives the calendar date of each day', () {
    final evening = DateTime.utc(2026, 10, 15, 21, 40);
    expect(ForecastDay.today.dateFrom(evening), DateTime.utc(2026, 10, 15));
    expect(ForecastDay.tomorrow.dateFrom(evening), DateTime.utc(2026, 10, 16));
    final lastDay = DateTime.utc(2026, 12, 31, 10);
    expect(ForecastDay.tomorrow.dateFrom(lastDay), DateTime.utc(2027));
  });

  test('defaults to work on weekdays and casual at the weekend', () {
    // 12 October 2026 is a Monday.
    for (var day = 12; day <= 16; day++) {
      expect(
        Occasion.defaultFor(DateTime.utc(2026, 10, day)),
        Occasion.work,
        reason: 'October $day',
      );
    }
    expect(Occasion.defaultFor(DateTime.utc(2026, 10, 17)), Occasion.casual);
    expect(Occasion.defaultFor(DateTime.utc(2026, 10, 18)), Occasion.casual);
  });
}
