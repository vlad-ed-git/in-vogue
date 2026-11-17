/// Background refresh cadence and widget date changes.
abstract final class WidgetSchedule {
  static const refreshEvery = Duration(hours: 6);

  /// A prompt first run, with room for foreground preparation to finish.
  static const firstRefresh = Duration(minutes: 15);

  /// The next six local midnights, accounting for daylight saving changes.
  static List<DateTime> changesAfter(DateTime time) => [
    for (var day = 1; day <= 6; day++)
      DateTime(time.year, time.month, time.day + day),
  ];
}
