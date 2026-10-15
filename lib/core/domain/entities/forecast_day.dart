/// The day a forecast or outfit is for.
enum ForecastDay {
  today,
  tomorrow;

  /// The day shown at local wall-clock [time]: today from 06:00 to 08:59,
  /// tomorrow otherwise.
  static ForecastDay shownAt(DateTime time) =>
      time.hour >= 6 && time.hour < 9 ? today : tomorrow;

  /// This day's date seen from local wall-clock [time], as midnight UTC.
  DateTime dateFrom(DateTime time) =>
      DateTime.utc(time.year, time.month, time.day + index);
}
