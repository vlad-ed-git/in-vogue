import CoreText
import ImageIO
import SwiftUI
import UIKit
import WidgetKit

/// The widget at its size, as the app's widget preview draws it
/// (HomeWidgetPreview); the Rouge field and the name before the app has given
/// it a day.
struct InVogueWidgetView: View {
  let entry: InVogueEntry
  @Environment(\.widgetFamily) private var family

  var body: some View {
    if let shown = entry.content?.shown(at: entry.date) {
      sized(shown)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(shown.spoken)
        .widgetURL(URL(string: shown.day.link))
    } else {
      Text(verbatim: "In Vogue")
        .font(WidgetType.condensed(40, weight: 700))
        .foregroundStyle(WidgetColor.rose)
    }
  }

  @ViewBuilder private func sized(_ shown: ShownDay) -> some View {
    let portrait = Portrait(
      picture: shown.day.picture.flatMap { entry.pictures[$0] },
      waiting: shown.day.waitingPhoto.flatMap { entry.pictures[$0] },
      gettingReady: shown.day.gettingReady,
      crop: family == .systemLarge
    )
    switch family {
    case .systemSmall: SmallDay(shown: shown)
    case .systemMedium: MediumDay(shown: shown, portrait: portrait)
    default: LargeDay(shown: shown, portrait: portrait)
    }
  }
}

/// Large: the slab, 154 of 338, beside the portrait running the full height.
struct LargeDay: View {
  let shown: ShownDay
  let portrait: Portrait

  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 0) {
          Heading(shown: shown, withDate: true)
          Spacer(minLength: 0)
          Numeral(temperature: shown.day.temperature, size: 150)
          Glyph(name: shown.day.glyph).padding(.top, 18)
          Text(shown.day.condition)
            .font(WidgetType.sofia(15, weight: 600))
            .foregroundStyle(WidgetColor.rose)
            .lineLimit(2)
            .padding(.top, 6)
          DateLine(text: shown.day.feelsLike).padding(.top, 4)
        }
        .padding(EdgeInsets(top: 18, leading: 16, bottom: 18, trailing: 0))
        .frame(width: geometry.size.width * 154 / 338, alignment: .leading)
        portrait
      }
    }
  }
}

/// Medium: the slab, 206 of 338, beside the portrait running the full height.
struct MediumDay: View {
  let shown: ShownDay
  let portrait: Portrait

  var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 0) {
        VStack(alignment: .leading, spacing: 0) {
          TopRow(shown: shown, withDate: true)
          Spacer(minLength: 0)
          HStack(alignment: .bottom, spacing: 12 - 5) {
            Numeral(temperature: shown.day.temperature, size: 118).layoutPriority(1)
            Text(shown.day.condition)
              .font(WidgetType.sofia(13, weight: 600))
              .foregroundStyle(WidgetColor.rose)
              .lineLimit(2)
              .padding(.bottom, 2)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 13, trailing: 14))
        .frame(width: geometry.size.width * 206 / 338, alignment: .leading)
        portrait
      }
    }
  }
}

/// Small: the slab is the whole widget; weather only, since a figure can't
/// be read this small.
struct SmallDay: View {
  let shown: ShownDay

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      TopRow(shown: shown, withDate: false)
      Spacer(minLength: 0)
      Numeral(temperature: shown.day.temperature, size: 104)
      Text(shown.day.condition)
        .font(WidgetType.sofia(11))
        .foregroundStyle(WidgetColor.rose)
        .lineLimit(2)
        .padding(.top, 8)
    }
    .padding(EdgeInsets(top: 14, leading: 16, bottom: 13, trailing: 14))
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

/// The day word and, but in Small, the date line.
struct Heading: View {
  let shown: ShownDay
  let withDate: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 3) {
      if !shown.kicker.isEmpty { Kicker(text: shown.kicker) }
      if withDate { DateLine(text: shown.dateLine) }
    }
  }
}

/// The heading with the weather glyph at its end.
struct TopRow: View {
  let shown: ShownDay
  let withDate: Bool

  var body: some View {
    HStack(alignment: .top, spacing: 8) {
      Heading(shown: shown, withDate: withDate)
        .frame(maxWidth: .infinity, alignment: .leading)
      Glyph(name: shown.day.glyph)
    }
  }
}

/// The day word at 11 points, tracked 12% in capitals; Chinese has none.
struct Kicker: View {
  let text: String

  var body: some View {
    Text(text)
      .font(WidgetType.sofia(11, weight: 700))
      .tracking(text.lowercased() != text.uppercased() ? 1.32 : 0)
      .foregroundStyle(WidgetColor.rose)
      .lineLimit(1)
  }
}

/// The date and occasion, the saved time, or feels-like.
struct DateLine: View {
  let text: String

  var body: some View {
    Text(text)
      .font(WidgetType.sofia(11))
      .foregroundStyle(WidgetColor.roseMuted)
      .lineLimit(1)
  }
}

/// The temperature, light and tight, with a lighter degree sign at 86%. It
/// shrinks only when the figures don't fit.
struct Numeral: View {
  let temperature: Int
  let size: CGFloat

  var body: some View {
    Text(figures)
      .font(WidgetType.condensed(size, weight: 300))
      .tracking(-0.025 * size)
      .foregroundStyle(WidgetColor.rose)
      .lineLimit(1)
      .minimumScaleFactor(0.5)
      // The spec's line height, 0.74 of the size, out of the font's 1.2.
      .padding(.top, -0.345 * size)
      .padding(.bottom, -0.115 * size)
      .offset(x: -5)
  }

  /// With a true minus sign below zero.
  private var figures: AttributedString {
    var text = AttributedString(temperature < 0 ? "−\(-temperature)" : "\(temperature)")
    var degree = AttributedString("°")
    degree.font = WidgetType.sofia(size * 0.86, weight: 200)
    text.append(degree)
    return text
  }
}

/// The spec's Phosphor Light weather glyph, in Rose.
struct Glyph: View {
  let name: String

  var body: some View {
    let image =
      UIImage(named: "widget_glyph_" + name.replacingOccurrences(of: "-", with: "_"))
      ?? UIImage(named: "widget_glyph_cloud")
    Group {
      if let image {
        Image(uiImage: image).renderingMode(.template).resizable()
      }
    }
    .foregroundStyle(WidgetColor.rose)
    .frame(width: 24, height: 24)
    .accessibilityHidden(true)
  }
}

/// The outfit's picture on studio grey, or the person's photo faded under
/// "Getting ready". Large crops the picture's sides; Medium contains it, so
/// head and shoes are never cut.
struct Portrait: View {
  let picture: UIImage?
  let waiting: UIImage?
  let gettingReady: String
  let crop: Bool

  var body: some View {
    ZStack {
      if let picture {
        WidgetColor.studio
        photo(picture)
      } else {
        if let waiting { photo(waiting).opacity(0.28) }
        Text(gettingReady)
          .font(WidgetType.sofia(15, weight: 600))
          .foregroundStyle(WidgetColor.rose)
          .multilineTextAlignment(.center)
          .lineLimit(2)
          .padding(.horizontal, 8)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
  }

  private func photo(_ image: UIImage) -> some View {
    Color.clear
      .overlay(
        Image(uiImage: image)
          .resizable()
          .fullColor()
          .aspectRatio(contentMode: crop ? .fill : .fit)
      )
      .clipped()
  }
}

extension Image {
  /// Keeps the picture's colours when the Home Screen tints widgets.
  @ViewBuilder func fullColor() -> some View {
    if #available(iOS 18.0, *) {
      widgetAccentedRenderingMode(.fullColor)
    } else {
      self
    }
  }
}

/// The widget's colours (widget_colors.xml on Android).
enum WidgetColor {
  static let rouge = Color(hex: 0x8C0F1F)
  static let rose = Color(hex: 0xF7D3D8)
  static let roseMuted = Color(hex: 0xE8AEB8)
  static let studio = Color(hex: 0xEDEDEB)
}

extension Color {
  fileprivate init(hex: UInt32) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 8) & 0xFF) / 255,
      blue: Double(hex & 0xFF) / 255,
      opacity: 1
    )
  }
}

/// The widget's type: the app's fonts at the weights the preview sets.
enum WidgetType {
  static func sofia(_ size: CGFloat, weight: CGFloat = 400) -> Font {
    variable("SofiaSans-Regular", size, weight)
  }

  /// For the temperature and the name.
  static func condensed(_ size: CGFloat, weight: CGFloat) -> Font {
    variable("SofiaSansExtraCondensed-Regular", size, weight)
  }

  /// The font at `weight` on its weight axis.
  private static func variable(_ name: String, _ size: CGFloat, _ weight: CGFloat) -> Font {
    let wght = 0x7767_6874  // 'wght'
    let attributes: [CFString: Any] = [
      kCTFontNameAttribute: name,
      kCTFontVariationAttribute: [wght: weight],
    ]
    let descriptor = CTFontDescriptorCreateWithAttributes(attributes as CFDictionary)
    return Font(CTFontCreateWithFontDescriptor(descriptor, size, nil))
  }
}

/// A picture the app shared, decoded at most `side` pixels on its long side.
enum WidgetPicture {
  static func load(_ path: String, side: Int) -> UIImage? {
    guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)
    else { return nil }
    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: side,
    ]
    guard let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    else { return nil }
    return UIImage(cgImage: image)
  }
}
