import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// The widget's content as the native widget reads it.
abstract final class WidgetContentModel {
  static const version = 1;

  /// [picturePath] tells where the widget reads each picture, null when it
  /// has no copy.
  static Map<String, Object?> toJson(
    WidgetContent content, {
    String? Function(String path) picturePath = _inPlace,
  }) => {
    'version': version,
    'preferred': content.preferred.name,
    'savedLine': content.savedLine,
    'days': [for (final day in content.days) _day(day, picturePath)],
  };

  /// Opens Home on [day]'s date and occasion. home_widget reports a tap on
  /// iPhone only when its link has `homeWidget`.
  static String link(WidgetSnapshot day) =>
      'invogue://home?date=${TryOnJob.dateKey(day.date)}'
      '&occasion=${day.occasion.name}&homeWidget';

  /// The tap a widget [link] stands for; null when it isn't one.
  static WidgetTap? tapOf(Uri? link) {
    if (link == null || link.scheme != 'invogue' || link.host != 'home') {
      return null;
    }
    final date = DateTime.tryParse('${link.queryParameters['date']}T00:00:00Z');
    final occasion = Occasion.values
        .asNameMap()[link.queryParameters['occasion']];
    if (date == null || occasion == null) return null;
    return WidgetTap(date: date, occasion: occasion);
  }

  static String? _inPlace(String path) => path;

  static String? _shared(
    String? path,
    String? Function(String path) picturePath,
  ) => path == null ? null : picturePath(path);

  static Map<String, Object?> _day(
    WidgetSnapshot day,
    String? Function(String path) picturePath,
  ) => {
    'date': TryOnJob.dateKey(day.date),
    'occasion': day.occasion.name,
    'today': day.today,
    'tomorrow': day.tomorrow,
    'dateLine': day.dateLine,
    'temperature': day.temperature,
    'condition': day.condition,
    'feelsLike': day.feelsLike,
    'glyph': day.glyph,
    'picture': _shared(day.picture, picturePath),
    'waitingPhoto': _shared(day.waitingPhoto, picturePath),
    'gettingReady': day.gettingReady,
    'spokenToday': day.spokenToday,
    'spokenTomorrow': day.spokenTomorrow,
    'link': link(day),
  };
}
