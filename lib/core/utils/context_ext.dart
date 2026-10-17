import 'package:flutter/material.dart';
import 'package:in_vogue/core/domain/entities/supported_languages.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

extension ContextExt on BuildContext {
  AppLocalizations get translated => AppLocalizations.of(this);

  /// The language the app is shown in.
  SupportedLanguages get language => SupportedLanguages.fromLanguageCode(
    Localizations.localeOf(this).languageCode,
  );
  ColorScheme get color => Theme.of(this).colorScheme;

  void showSnack({required String message, bool isError = false}) {
    ScaffoldMessenger.of(this)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? color.error : null,
        ),
      );
  }
}
