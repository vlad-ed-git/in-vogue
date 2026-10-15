import 'package:flutter_test/flutter_test.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';

void main() {
  test(
    'a new installation and unknown stored languages default to English',
    () {
      for (final code in <String?>[null, '', 'fr', 'future-language']) {
        expect(
          SupportedLanguages.fromLanguageCode(code),
          SupportedLanguages.english,
        );
      }
    },
  );

  test('restores every supported language', () {
    for (final language in SupportedLanguages.values) {
      expect(
        SupportedLanguages.fromLanguageCode(language.languageCode),
        language,
      );
    }
  });
}
