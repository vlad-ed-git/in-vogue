// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'In Vogue';

  @override
  String get tagline => 'Meet tomorrow’s weather in style.';

  @override
  String get welcomeDescription =>
      'Outfits for your day. Makeup for your look.';

  @override
  String get language => 'Language';

  @override
  String get cacheFailure => 'We couldn’t save your changes. Please try again.';

  @override
  String get networkFailure => 'You’re offline. Please check your connection.';

  @override
  String get serverFailure => 'Something went wrong. Please try again.';

  @override
  String get startupFailure => 'In Vogue couldn’t start. Please try again.';

  @override
  String get retry => 'Try again';
}
