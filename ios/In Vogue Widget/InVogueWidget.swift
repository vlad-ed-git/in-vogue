import SwiftUI
import UIKit
import WidgetKit

/// The home-screen widget: the day's weather on a Rouge slab beside the
/// person in the day's outfit. The app keeps today's and tomorrow's days and
/// reloads the widget whenever they change; the widget picks the day itself,
/// as Home does, and changes at 06:00, 09:00 and midnight.
struct InVogueWidget: Widget {
  /// HomeWidgetDataSourceImpl.iOSKind in the app.
  let kind = "InVogueWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: InVogueTimeline()) { entry in
      InVogueWidgetView(entry: entry)
        .containerBackground(WidgetColor.rouge, for: .widget)
    }
    .configurationDisplayName("In Vogue")
    .description("")
    .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    .contentMarginsDisabled()
  }
}

/// The content the app kept, read at `date`, with its pictures sized for the
/// widget, by the path the app gave.
struct InVogueEntry: TimelineEntry {
  let date: Date
  let content: WidgetContent?
  let pictures: [String: UIImage]
}

struct InVogueTimeline: TimelineProvider {
  func placeholder(in context: Context) -> InVogueEntry {
    InVogueEntry(date: Date(), content: nil, pictures: [:])
  }

  func getSnapshot(in context: Context, completion: @escaping (InVogueEntry) -> Void) {
    completion(entry(at: Date(), family: context.family))
  }

  /// An entry now and at each coming change of day.
  func getTimeline(in context: Context, completion: @escaping (Timeline<InVogueEntry>) -> Void) {
    let now = Date()
    let first = entry(at: now, family: context.family)
    let later = Calendar.widget.changes(after: now).map {
      InVogueEntry(date: $0, content: first.content, pictures: first.pictures)
    }
    completion(Timeline(entries: [first] + later, policy: .atEnd))
  }

  private func entry(at date: Date, family: WidgetFamily) -> InVogueEntry {
    let content = WidgetContent.saved()
    // Small shows no picture. WidgetKit refuses images larger than the widget.
    let side = switch family {
    case .systemLarge: 900
    case .systemMedium: 600
    default: 0
    }
    var pictures: [String: UIImage] = [:]
    if side > 0 {
      let paths = content?.days.flatMap { [$0.picture, $0.waitingPhoto].compactMap { $0 } } ?? []
      for path in Set(paths) {
        pictures[path] = WidgetPicture.load(path, side: side)
      }
    }
    return InVogueEntry(date: date, content: content, pictures: pictures)
  }
}
