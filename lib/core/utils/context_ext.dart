import 'package:flutter/material.dart';
import 'package:in_vogue/l10n/generated/app_localizations.dart';

extension ContextExt on BuildContext {
  AppLocalizations get translated => AppLocalizations.of(this);
  ColorScheme get color => Theme.of(this).colorScheme;
  TextTheme get txtTheme => Theme.of(this).textTheme;
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;

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
