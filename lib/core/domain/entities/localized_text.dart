import 'package:equatable/equatable.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';

/// A knowledge-base text in the languages it was written in; English is
/// always there.
class LocalizedText extends Equatable {
  const LocalizedText(this.english, {this.translations = const {}});

  final String english;

  /// The text in other languages, by language code.
  final Map<String, String> translations;

  /// [json] as a plain English text or as texts by language code; null
  /// when it has no English.
  static LocalizedText? fromJson(Object? json) => switch (json) {
    final String english => LocalizedText(english),
    {'en': final String english} && final Map<Object?, Object?> texts =>
      LocalizedText(
        english,
        translations: {
          for (final MapEntry(:key, :value) in texts.entries)
            if (key is String && key != 'en' && value is String) key: value,
        },
      ),
    _ => null,
  };

  /// The text in [language], else in English.
  String of(SupportedLanguages language) =>
      translations[language.languageCode] ?? english;

  Map<String, String> toJson() => {'en': english, ...translations};

  @override
  List<Object?> get props => [english, translations];
}
