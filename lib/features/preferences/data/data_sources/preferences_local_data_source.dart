import 'dart:convert';

import 'package:in_vogue/core/domain/entities/forecast_day.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/core/persistence/key_value_store.dart';

abstract interface class PreferencesLocalDataSource {
  SupportedLanguages getLanguage();
  Future<void> setLanguage(SupportedLanguages language);

  /// The day Home opens on; tomorrow when none is chosen.
  ForecastDay getDefaultDay();
  Future<void> setDefaultDay(ForecastDay day);

  /// The occasion's name chosen for each date, by its "yyyy-mm-dd".
  Map<String, String> getOccasions();
  Future<void> setOccasions(Map<String, String> occasions);
}

class PreferencesLocalDataSourceImpl implements PreferencesLocalDataSource {
  PreferencesLocalDataSourceImpl(this._store);
  final KeyValueStore _store;
  static const languageKey = 'language';
  static const defaultDayKey = 'default_day';
  static const occasionsKey = 'occasions';

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

  @override
  Map<String, String> getOccasions() {
    final saved = _store.readString(occasionsKey);
    if (saved == null) return {};
    try {
      return switch (jsonDecode(saved)) {
        final Map<String, Object?> json => {
          for (final MapEntry(:key, :value) in json.entries)
            if (value is String) key: value,
        },
        _ => {},
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> setOccasions(Map<String, String> occasions) =>
      _store.writeString(occasionsKey, jsonEncode(occasions));
}
