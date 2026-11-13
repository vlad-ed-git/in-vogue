import Foundation

/// The widget's content as the app keeps it (WidgetContentModel in the app):
/// today's and tomorrow's days, their words already in the person's language.
struct WidgetContent: Decodable {
  let preferred: String
  let savedLine: String
  let days: [WidgetDay]

  /// The App Group the app keeps the content in: development's for the
  /// development flavor's widget (HomeWidgetDataSourceImpl.appGroupOf), else
  /// production's.
  static var appGroup: String {
    Bundle.main.bundleIdentifier?.hasPrefix("com.invogue.app.dev.") == true
      ? "group.com.invogue.app.dev"
      : "group.com.invogue.app"
  }

  /// What the app kept (HomeWidgetDataSourceImpl.contentKey); nil before it
  /// kept anything, and after log out.
  static func saved() -> WidgetContent? {
    guard
      let json = UserDefaults(suiteName: appGroup)?.string(forKey: "in_vogue_widget"),
      let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(WidgetContent.self, from: data)
  }

  /// The preferred day, or the newest saved snapshot labelled with its age.
  func shown(at now: Date, calendar: Calendar = .widget) -> ShownDay? {
    let today = calendar.key(of: now)
    let tomorrow = calendar.key(of: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
    let target = preferred == "today" ? today : tomorrow
    if let day = days.first(where: { $0.date == target }) {
      let isToday = day.date == today
      return ShownDay(
        day: day,
        kicker: isToday ? day.today : day.tomorrow,
        dateLine: day.dateLine,
        spoken: isToday ? day.spokenToday : day.spokenTomorrow
      )
    }
    guard let newest = days.max(by: { $0.date < $1.date }) else { return nil }
    return ShownDay(day: newest, kicker: "", dateLine: savedLine, spoken: savedLine)
  }
}

/// A day as the widget shows it.
struct WidgetDay: Decodable {
  let date: String
  let today: String
  let tomorrow: String
  let dateLine: String
  let temperature: Int
  let condition: String
  let feelsLike: String
  let glyph: String
  /// The outfit's picture, copied where the widget can read it; nil until it
  /// is made.
  let picture: String?
  /// The person's photo, shown faded under `gettingReady` while there is no
  /// picture.
  let waitingPhoto: String?
  let gettingReady: String
  let spokenToday: String
  let spokenTomorrow: String
  /// Opens Home on this day and occasion.
  let link: String
}

/// The day on show, with its kicker, date line and spoken words as they read
/// now.
struct ShownDay {
  let day: WidgetDay
  let kicker: String
  let dateLine: String
  let spoken: String
}

extension Calendar {
  /// Gregorian in the phone's time zone, as the app's date keys are.
  static var widget: Calendar {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    return calendar
  }

  /// The date's key, such as "2026-10-19".
  func key(of date: Date) -> String {
    let day = dateComponents([.year, .month, .day], from: date)
    return String(format: "%04ld-%02ld-%02ld", day.year ?? 0, day.month ?? 0, day.day ?? 0)
  }

  /// The next six midnights, matching WidgetSchedule.changesAfter.
  func changes(after now: Date) -> [Date] {
    let start = startOfDay(for: now)
    var changes: [Date] = []
    for offset in 1...6 {
      if let change = date(byAdding: .day, value: offset, to: start) {
        changes.append(change)
      }
    }
    return changes
  }
}
