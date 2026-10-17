import 'package:in_vogue/core/domain/entities/forecast_day.dart';

/// When the widget's day changes. The native widget mirrors [dayAt].
abstract final class WidgetSchedule {
  /// The day shown at local [time]: always today when [preferred] is today,
  /// else Home's morning rule.
  static ForecastDay dayAt(ForecastDay preferred, DateTime time) =>
      preferred == ForecastDay.today
      ? ForecastDay.today
      : ForecastDay.shownAt(time);

  /// How long from [time] until the next background refresh, at 05:30, so
  /// the 06:00 change shows fresh weather.
  static Duration untilRefresh(DateTime time) {
    var next = DateTime(time.year, time.month, time.day, 5, 30);
    if (!next.isAfter(time)) {
      next = DateTime(time.year, time.month, time.day + 1, 5, 30);
    }
    return next.difference(time);
  }

  /// The next six local times after [time] when the day shown can change:
  /// 06:00, 09:00 and midnight.
  static List<DateTime> changesAfter(DateTime time) => [
    for (var day = 0; day <= 2; day++)
      for (final hour in const [0, 6, 9])
        DateTime(time.year, time.month, time.day + day, hour),
  ].where((change) => change.isAfter(time)).take(6).toList();
}
