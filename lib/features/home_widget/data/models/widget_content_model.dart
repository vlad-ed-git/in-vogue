import 'package:in_vogue/core/domain/entities/occasion.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_content.dart';
import 'package:in_vogue/features/home_widget/domain/entities/widget_tap.dart';
import 'package:in_vogue/features/outfits/domain/entities/try_on_job.dart';

/// The widget's content as the native widget reads it.
abstract final class WidgetContentModel {
  static const version = 1;

  static Map<String, Object?> toJson(WidgetContent content) => {
    'version': version,
    'preferred': content.preferred.name,
    'savedLine': content.savedLine,
    'days': [for (final day in content.days) _day(day)],
  };

  /// Opens Home on [day]'s date and occasion.
  static String link(WidgetSnapshot day) =>
      'invogue://home?date=${TryOnJob.dateKey(day.date)}'
      '&occasion=${day.occasion.name}';

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

  static Map<String, Object?> _day(WidgetSnapshot day) => {
    'date': TryOnJob.dateKey(day.date),
    'occasion': day.occasion.name,
    'today': day.today,
    'tomorrow': day.tomorrow,
    'dateLine': day.dateLine,
    'temperature': day.temperature,
    'condition': day.condition,
    'feelsLike': day.feelsLike,
    'glyph': day.glyph,
    'picture': day.picture,
    'waitingPhoto': day.waitingPhoto,
    'gettingReady': day.gettingReady,
    'spokenToday': day.spokenToday,
    'spokenTomorrow': day.spokenTomorrow,
    'link': link(day),
  };
}
