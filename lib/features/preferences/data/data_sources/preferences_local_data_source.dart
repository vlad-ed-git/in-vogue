import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';

abstract interface class PreferencesLocalDataSource {
  SupportedLanguages getLanguage();
  Future<void> setLanguage(SupportedLanguages language);

  /// The day Home opens on; tomorrow when none is chosen.
  ForecastDay getDefaultDay();
  Future<void> setDefaultDay(ForecastDay day);
}

class PreferencesLocalDataSourceImpl implements PreferencesLocalDataSource {
  PreferencesLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const languageKey = 'language';
  static const defaultDayKey = 'default_day';

  @override
  SupportedLanguages getLanguage() =>
      SupportedLanguages.fromLanguageCode(_store.readString(languageKey));

  @override
  Future<void> setLanguage(SupportedLanguages language) =>
      _store.writeString(languageKey, language.languageCode);

  @override
  ForecastDay getDefaultDay() =>
      ForecastDay.values.asNameMap()[_store.readString(defaultDayKey)] ??
      ForecastDay.tomorrow;

  @override
  Future<void> setDefaultDay(ForecastDay day) =>
      _store.writeString(defaultDayKey, day.name);
}
