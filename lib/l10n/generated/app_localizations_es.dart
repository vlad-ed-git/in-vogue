// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'In Vogue';

  @override
  String get tagline => 'Viste con estilo para el tiempo de mañana.';

  @override
  String get welcomeDescription =>
      'Conjuntos para tu día. Maquillaje para tu look.';

  @override
  String get language => 'Idioma';

  @override
  String get cacheFailure =>
      'No pudimos guardar tus cambios. Inténtalo de nuevo.';

  @override
  String get networkFailure =>
      'No tienes conexión. Revisa tu conexión a internet.';

  @override
  String get serverFailure => 'Algo salió mal. Inténtalo de nuevo.';

  @override
  String get startupFailure =>
      'In Vogue no pudo iniciarse. Inténtalo de nuevo.';

  @override
  String get retry => 'Reintentar';
}
