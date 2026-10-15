import 'package:flutter/widgets.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';

extension SupportedLanguageLocale on SupportedLanguages {
  Locale get locale => Locale(languageCode);
}
