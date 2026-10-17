import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/localized_text.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';

void main() {
  test('reads a plain text as English, shown in every language', () {
    final text = LocalizedText.fromJson('Light base')!;
    for (final language in SupportedLanguages.values) {
      expect(text.of(language), 'Light base');
    }
  });

  test('reads a text in each language, falling back to English', () {
    final text = LocalizedText.fromJson({
      'en': 'Light base',
      'es': 'Base ligera',
    })!;
    expect(text.of(SupportedLanguages.english), 'Light base');
    expect(text.of(SupportedLanguages.spanish), 'Base ligera');
    expect(text.of(SupportedLanguages.chinese), 'Light base');
    expect(LocalizedText.fromJson(text.toJson()), text);
  });

  test('has nothing to read without English', () {
    expect(LocalizedText.fromJson({'es': 'Base ligera'}), isNull);
    expect(LocalizedText.fromJson(null), isNull);
    expect(LocalizedText.fromJson(3), isNull);
  });
}
