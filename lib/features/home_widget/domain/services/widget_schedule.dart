/// Background refresh cadence and widget date changes.
abstract final class WidgetSchedule {
  static const refreshEvery = Duration(hours: 6);
  static const firstRefresh = Duration(minutes: 15);

  /// A prompt first run, with room for foreground preparation to finish.
  static Duration untilRefresh(DateTime time) => firstRefresh;

  /// The next six local midnights, accounting for daylight saving changes.
  static List<DateTime> changesAfter(DateTime time) => [
    for (var day = 1; day <= 6; day++)
      DateTime(time.year, time.month, time.day + day),
  ];
}
