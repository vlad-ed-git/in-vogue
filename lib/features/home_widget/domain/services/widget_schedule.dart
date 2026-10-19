/// When the widget's day changes.
abstract final class WidgetSchedule {
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
