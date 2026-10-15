import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';

abstract interface class PreferencesLocalDataSource {
  SupportedLanguages getLanguage();
  Future<void> setLanguage(SupportedLanguages language);
}

class PreferencesLocalDataSourceImpl implements PreferencesLocalDataSource {
  PreferencesLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const languageKey = 'language';

  @override
  SupportedLanguages getLanguage() =>
      SupportedLanguages.fromLanguageCode(_store.readString(languageKey));

  @override
  Future<void> setLanguage(SupportedLanguages language) =>
      _store.writeString(languageKey, language.languageCode);
}
