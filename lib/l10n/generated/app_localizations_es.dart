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

  @override
  String get back => 'Atrás';

  @override
  String get close => 'Cerrar';

  @override
  String setupFolio(int step, int total) {
    return '$step / $total';
  }

  @override
  String get yourPicks => 'Tu selección';

  @override
  String yourPicksCount(int count) {
    return 'Tu selección · $count';
  }

  @override
  String get today => 'Hoy';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get before => 'Antes';

  @override
  String get after => 'Después';

  @override
  String get tabHome => 'Inicio';

  @override
  String get tabMakeup => 'Maquillaje';

  @override
  String get tabSettings => 'Ajustes';

  @override
  String temperatureSpoken(int temperature) {
    return '$temperature grados';
  }

  @override
  String feelsLike(int temperature) {
    return 'Sensación de $temperature°';
  }

  @override
  String weatherSpoken(int temperature, String condition, int feelsLike) {
    return '$temperature grados, $condition, sensación de $feelsLike.';
  }

  @override
  String weatherSpokenWithDay(
    String day,
    int temperature,
    String condition,
    int feelsLike,
  ) {
    return '$day, $temperature grados, $condition, sensación de $feelsLike.';
  }

  @override
  String get occasionWork => 'Trabajo';

  @override
  String get occasionCasual => 'Informal';

  @override
  String get occasionGoingOut => 'Salir';

  @override
  String get occasionStayingIn => 'En casa';

  @override
  String get occasionWorkKicker => 'Día laborable';

  @override
  String get occasionCasualKicker => 'Informal';

  @override
  String get occasionGoingOutKicker => 'Salir';

  @override
  String get occasionStayingInKicker => 'En casa';

  @override
  String get change => 'Cambiar';

  @override
  String dayIs(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': 'Hoy es',
      'other': 'Mañana es',
    });
    return '$_temp0';
  }

  @override
  String get gettingOutfitReady => 'Preparando tu conjunto…';

  @override
  String get tryOnFailed => 'Esta vez no pudimos vestirte. Tu foto está bien.';

  @override
  String get locationOff => 'In Vogue necesita tu ubicación para el tiempo.';

  @override
  String get openSettings => 'Abrir ajustes';

  @override
  String offlineSaved(String savedAt) {
    return 'No tienes conexión. Este es el conjunto guardado el $savedAt.';
  }

  @override
  String savedAt(String date, String time) {
    return '$date a las $time';
  }

  @override
  String everyLookSeen(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today':
          'Ya viste todos los conjuntos para hoy. Pronto llegan prendas nuevas.',
      'other':
          'Ya viste todos los conjuntos para mañana. Pronto llegan prendas nuevas.',
    });
    return '$_temp0';
  }

  @override
  String get notFullLength => 'Esta foto no te muestra de pies a cabeza.';

  @override
  String get chooseAnotherPhoto => 'Elegir otra foto';

  @override
  String get chooseDifferentPhoto => 'Elegir una foto distinta';

  @override
  String get chooseFromPhotos => 'Elegir de Fotos';

  @override
  String get chooseFromGallery => 'Elegir de la Galería';

  @override
  String get continueAction => 'Continuar';

  @override
  String get example => 'Ejemplo';

  @override
  String get yourPhoto => 'Tu foto';

  @override
  String get photoPasses => 'Tu foto sirve';

  @override
  String get photoHeadToToe => 'De pies a cabeza';

  @override
  String get photoStanding => 'De pie, de frente';

  @override
  String get photoGoodLight => 'Buena luz';

  @override
  String get photoJustYou => 'Solo tú';

  @override
  String get photoCloseUp => 'De cerca';

  @override
  String get photoFacingForward => 'De frente';

  @override
  String get photoDaylight => 'Luz natural';

  @override
  String get photoHairOff => 'Pelo fuera de la cara';

  @override
  String get bodyPhotoPrivacy =>
      'Tu foto solo se usa para vestirte con los conjuntos. Puedes cambiarla cuando quieras.';

  @override
  String get exampleBodySpoken =>
      'Ejemplo: una mujer fotografiada de pies a cabeza, de frente, con luz uniforme';

  @override
  String get exampleFaceSpoken =>
      'Ejemplo: un rostro fotografiado de cerca, de frente, con luz natural';

  @override
  String get otherOutfitsPreparing => 'Otros conjuntos están en camino.';

  @override
  String get otherOutfitsLocked => 'Los otros conjuntos vienen con Pro.';

  @override
  String get goPro => 'Hazte Pro';

  @override
  String outfitTileSpoken(int index, int count) {
    return 'Conjunto $index de $count';
  }

  @override
  String outfitTileShownSpoken(int index, int count) {
    return 'Conjunto $index de $count, en pantalla';
  }

  @override
  String get lockedSpoken => 'Incluido en Pro';

  @override
  String planFree(int outfits, int looks) {
    String _temp0 = intl.Intl.pluralLogic(
      outfits,
      locale: localeName,
      other: '$outfits conjuntos',
      one: '1 conjunto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      looks,
      locale: localeName,
      other: '$looks looks de maquillaje',
      one: '1 look de maquillaje',
    );
    return 'Plan gratuito · te quedan $_temp0 y $_temp1';
  }

  @override
  String get planNoOutfits => 'Plan gratuito · no te quedan conjuntos';

  @override
  String planMakeupLeft(int looks) {
    String _temp0 = intl.Intl.pluralLogic(
      looks,
      locale: localeName,
      other: 'te quedan $looks looks de maquillaje',
      one: 'te queda 1 look de maquillaje',
      zero: 'no te quedan looks de maquillaje',
    );
    return 'Plan gratuito · $_temp0';
  }

  @override
  String get onProList => 'En la lista de Pro ✓';

  @override
  String loveSpoken(String name) {
    return 'Me gusta $name';
  }

  @override
  String get loved => 'Te gusta';

  @override
  String get loveThisColour => 'Me gusta este color';

  @override
  String colourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colores',
      one: '1 color',
    );
    return '$_temp0';
  }

  @override
  String moreColours(int count) {
    return '+$count';
  }

  @override
  String get proceed => 'Seguir';

  @override
  String get done => 'Listo';

  @override
  String buyAt(String brand) {
    return 'Comprar en $brand';
  }

  @override
  String noLongerAvailable(String brand) {
    return 'Ya no está disponible en $brand';
  }

  @override
  String catalogPhotoSpoken(String name, String colour) {
    return '$name en $colour, foto del catálogo';
  }

  @override
  String get preparing => 'Preparando';

  @override
  String faceAfterStep(int step) {
    return 'Tu cara después del paso $step';
  }

  @override
  String get faceWithLook => 'Tu cara con el look terminado';

  @override
  String get facePhotoSpoken => 'Tu foto de la cara';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get proName => 'In Vogue Pro';

  @override
  String get proLine => 'Más conjuntos, más opciones y maquillaje para todos.';

  @override
  String get proBenefitDaily => 'Un conjunto nuevo cada día';

  @override
  String get proBenefitChoice => 'Otros conjuntos para elegir';

  @override
  String get proBenefitCollection => 'Toda la colección para explorar';

  @override
  String get proBenefitMakeup => 'Maquillaje para cada conjunto';

  @override
  String get proPrice => '\$7.99 al mes · o \$59.99 al año';

  @override
  String get onTheList => 'Estás en la lista.';

  @override
  String get proSoon => 'Pro abre pronto y serás la primera en saberlo.';

  @override
  String get backToInVogue => 'Volver a In Vogue';

  @override
  String get widgetStepHold => 'Mantén pulsada la pantalla de inicio';

  @override
  String get widgetStepPlus => 'Toca +';

  @override
  String get widgetStepChoose => 'Elige In Vogue';

  @override
  String get widgetGettingReady => 'Preparando';

  @override
  String widgetSaved(String when) {
    return 'Guardado $when';
  }

  @override
  String get signInWithApple => 'Iniciar sesión con Apple';

  @override
  String get signInWithGoogle => 'Iniciar sesión con Google';
}
