enum SupportedLanguages {
  english('en', nativeName: 'English'),
  spanish('es', nativeName: 'Español'),
  chinese('zh', nativeName: '中文');

  const SupportedLanguages(this.languageCode, {required this.nativeName});

  final String languageCode;
  final String nativeName;
  static const defaultLanguage = english;

  static SupportedLanguages fromLanguageCode(String? code) {
    return values.firstWhere(
      (language) => language.languageCode == code,
      orElse: () => defaultLanguage,
    );
  }
}
