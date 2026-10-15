import 'package:intl/intl.dart';

/// The formats of `design-spec/guide/07-voice.md`, per language.
///
/// English: "Thu 16 Oct" in tight spots, "Thursday 16 October" in sheets,
/// "3 pm" and "9:12 pm". Spanish and Chinese use their own conventions
/// (24-hour time). Intl date symbols for the locale must be loaded; the
/// app's localization delegates do that.
abstract final class InVogueFormat {
  /// "Thu 16 Oct".
  static String shortDate(DateTime date, String languageCode) =>
      switch (languageCode) {
        'zh' => DateFormat('M月d日 EEE', 'zh').format(date),
        'es' => DateFormat('EEE d MMM', 'es').format(date),
        _ => DateFormat('EEE d MMM', 'en').format(date),
      };

  /// "Thursday 16 October".
  static String longDate(DateTime date, String languageCode) =>
      switch (languageCode) {
        'zh' => DateFormat('M月d日EEEE', 'zh').format(date),
        'es' => DateFormat("EEEE d 'de' MMMM", 'es').format(date),
        _ => DateFormat('EEEE d MMMM', 'en').format(date),
      };

  /// "3 pm", "9:12 pm"; "15:00" in Spanish and Chinese.
  static String time(DateTime date, String languageCode) {
    if (languageCode != 'en') {
      return DateFormat('H:mm', languageCode).format(date);
    }
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final period = date.hour < 12 ? 'am' : 'pm';
    final minutes = date.minute == 0
        ? ''
        : ':${date.minute.toString().padLeft(2, '0')}';
    return '$hour$minutes $period';
  }
}
