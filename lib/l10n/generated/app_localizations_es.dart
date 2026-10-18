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
  String get tagline => 'Viste con estilo para el tiempo de mañana';

  @override
  String get welcomeDescription =>
      'Mírate con un conjunto elegido para el tiempo de mañana, con un enlace para comprar cada prenda.';

  @override
  String get useMyLocation => 'Usar mi ubicación';

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
  String get tabHome => 'Inicio';

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
  String weatherFrom(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': 'Lluvia desde las $time',
      'showers': 'Chubascos desde las $time',
      'drizzle': 'Llovizna desde las $time',
      'snow': 'Nieve desde las $time',
      'storm': 'Tormentas desde las $time',
      'other': 'Viento fuerte desde las $time',
    });
    return '$_temp0';
  }

  @override
  String weatherUntil(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': 'Lluvia hasta las $time',
      'showers': 'Chubascos hasta las $time',
      'drizzle': 'Llovizna hasta las $time',
      'snow': 'Nieve hasta las $time',
      'storm': 'Tormentas hasta las $time',
      'other': 'Viento fuerte hasta las $time',
    });
    return '$_temp0';
  }

  @override
  String weatherAllDay(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': 'Lluvia todo el día',
      'showers': 'Chubascos todo el día',
      'drizzle': 'Llovizna todo el día',
      'snow': 'Nieve todo el día',
      'storm': 'Tormentas todo el día',
      'other': 'Viento fuerte todo el día',
    });
    return '$_temp0';
  }

  @override
  String weatherSky(String sky) {
    String _temp0 = intl.Intl.selectLogic(sky, {
      'clear': 'Soleado',
      'partlyCloudy': 'Parcialmente nublado',
      'cloudy': 'Nublado',
      'fog': 'Niebla',
      'other': 'Seco todo el día',
    });
    return '$_temp0';
  }

  @override
  String dayDatePlace(String day, String date, String place) {
    return '$day, $date · $place';
  }

  @override
  String dayDate(String day, String date) {
    return '$day, $date';
  }

  @override
  String get weatherUnavailable => 'No pudimos obtener el tiempo.';

  @override
  String weatherSaved(String savedAt) {
    return 'Se muestra el pronóstico guardado el $savedAt.';
  }

  @override
  String get picksTitle => 'Elige algunas que te gusten';

  @override
  String picksLine(String heart) {
    return 'Toca $heart en algunas prendas para este tiempo. Así aprendemos tu estilo.';
  }

  @override
  String get heartSpoken => 'corazón';

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
  String get locationUnavailable => 'No pudimos encontrar dónde estás.';

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
  String get photoUnreadable => 'No pudimos abrir esta foto. Elige otra.';

  @override
  String get photoTooSmall =>
      'Esta foto es demasiado pequeña. Elige una más grande.';

  @override
  String get photoUnusable => 'No podemos usar esta foto. Elige otra.';

  @override
  String get photoConverted =>
      'Cambiamos el formato de esta foto para que funcione. ¿No te gusta? Elige otra.';

  @override
  String get addPhotoOfYou => 'Añade una foto tuya';

  @override
  String get bodyPhotoWhy => 'Vestimos esta foto con cada conjunto.';

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
  String planFree(int outfits) {
    String _temp0 = intl.Intl.pluralLogic(
      outfits,
      locale: localeName,
      other: '$outfits conjuntos',
      one: '1 conjunto',
    );
    return 'Plan gratuito · te quedan $_temp0';
  }

  @override
  String get planNoOutfits => 'Plan gratuito · no te quedan conjuntos';

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
  String get logOut => 'Cerrar sesión';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get proName => 'In Vogue Pro';

  @override
  String get proLine => 'Más conjuntos y más opciones.';

  @override
  String get proBenefitDaily => 'Un conjunto nuevo cada día';

  @override
  String get proBenefitChoice => 'Otros conjuntos para elegir';

  @override
  String get proBenefitCollection => 'Toda la colección para explorar';

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

  @override
  String get signInTitle => 'Inicia sesión';

  @override
  String get signInLine =>
      'Tu foto y tus favoritos vienen contigo. Luego preparamos tu primer conjunto.';

  @override
  String get signInFailed =>
      'No pudimos iniciar tu sesión. Inténtalo de nuevo.';

  @override
  String get aboutYouTitle => '¿Cómo te llamamos?';

  @override
  String get yourName => 'Tu nombre';

  @override
  String get facePhotoTitle => 'Añade un selfie';

  @override
  String get facePhotoLine =>
      'Opcional. Sirve para analizar tu tono de piel y tus colores.';

  @override
  String get addWidgetTitle => 'Añade In Vogue a tu pantalla de inicio';

  @override
  String get addWidgetLine =>
      'El tiempo de mañana y tu conjunto, sin abrir la app.';

  @override
  String get addToHomeScreen => 'Añadir a la pantalla de inicio';

  @override
  String get skip => 'Omitir';

  @override
  String get widgetStepsTitle => 'Tres pasos en el iPhone';

  @override
  String get widgetAddByHand =>
      'Añádelo desde tu pantalla de inicio: mantén pulsado, toca Widgets y elige In Vogue.';

  @override
  String widgetPreviewSpoken(String weather) {
    return '$weather Tu conjunto se está preparando.';
  }

  @override
  String get tryOnPhotoProblem =>
      'No pudimos vestir esta foto. Puede que otra funcione.';

  @override
  String get tryOnNoCredit => 'Por ahora no se pueden crear más conjuntos.';

  @override
  String get tryOnUnavailable =>
      'Los conjuntos aún no están disponibles en esta versión.';

  @override
  String get shop => 'Comprar';

  @override
  String get shopThisOutfit => 'Compra este conjunto';

  @override
  String get aboutThisOutfit => 'Sobre este conjunto';

  @override
  String tryOnPiece(int piece, int pieces) {
    return 'Prenda $piece de $pieces';
  }

  @override
  String outfitPhotoSpoken(String about) {
    return 'Tú, de pies a cabeza, con tu conjunto. $about';
  }

  @override
  String get noPicks => 'Aún no has elegido nada.';

  @override
  String get removePickTitle => '¿Quitar de tu selección?';

  @override
  String get remove => 'Quitar';

  @override
  String get keep => 'Conservar';

  @override
  String get outfitsTab => 'Conjuntos';

  @override
  String get weatherHot => 'Calor';

  @override
  String get weatherWarm => 'Cálido';

  @override
  String get weatherMild => 'Templado';

  @override
  String get weatherCool => 'Fresco';

  @override
  String get weatherCold => 'Frío';

  @override
  String get weatherRain => 'Lluvia';

  @override
  String feelsLikeFrom(int low) {
    return 'Sensación de $low° o más';
  }

  @override
  String feelsLikeRange(int low, int high) {
    return 'Sensación de $low a $high°';
  }

  @override
  String feelsLikeBelow(int high) {
    return 'Sensación por debajo de $high°';
  }

  @override
  String get waterResistantPieces => 'Prendas resistentes al agua';

  @override
  String get edit => 'Editar';

  @override
  String get replace => 'Cambiar';

  @override
  String get add => 'Añadir';

  @override
  String get save => 'Guardar';

  @override
  String signedInWith(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'apple': 'Sesión iniciada con Apple',
      'other': 'Sesión iniciada con Google',
    });
    return '$_temp0';
  }

  @override
  String get bodyPhoto => 'Foto de cuerpo entero';

  @override
  String get bodyPhotoUse => 'Se usa para vestirte';

  @override
  String get facePhoto => 'Foto de la cara';

  @override
  String get facePhotoUse => 'Para analizar tus colores';

  @override
  String get notAdded => 'Aún no añadida';

  @override
  String get membership => 'Membresía';

  @override
  String get planPro => 'Pro';

  @override
  String get planFreeName => 'Plan gratuito';

  @override
  String get location => 'Ubicación';

  @override
  String locationWhileUsing(String city) {
    return '$city, mientras usas la app';
  }

  @override
  String get locationNotSet => 'Sin definir';

  @override
  String get defaultDay => 'Día predeterminado';

  @override
  String get homeScreenWidget => 'Widget de la pantalla de inicio';

  @override
  String get defaultDayTomorrow => 'Mañana; hoy de 6 a 9 de la mañana';

  @override
  String get defaultDayTitle => 'Inicio se abre en';

  @override
  String get deleteAccountTitle => '¿Eliminar tu cuenta?';

  @override
  String get deleteAccountLine =>
      'Se eliminarán tu perfil, tus fotos, tu selección y tus conjuntos. Lo confirmarás con Apple o Google. No se puede deshacer.';

  @override
  String get keepAccount => 'Conservar mi cuenta';

  @override
  String get loading => 'Cargando';

  @override
  String get photoLookStraight =>
      'En esta foto tu cara está girada o inclinada. Elige una en la que mires al frente.';

  @override
  String get photoMoveCloser =>
      'En esta foto tu cara se ve demasiado pequeña. Elige una más cercana.';

  @override
  String get photoShowWholeFace =>
      'En esta foto se corta parte de tu cara. Elige una en la que se vea entera.';

  @override
  String get photoOnlyYou =>
      'En esta foto hay más de una persona. Elige una en la que salgas solo tú.';

  @override
  String get photoStandHeadToToe =>
      'En esta foto no te vemos de pie. Elige una en la que estés de pie, de pies a cabeza.';

  @override
  String get tabMirror => 'Espejo';

  @override
  String get selfieTitle => 'Descubre tus colores';

  @override
  String get selfieLine =>
      'Añade un selfie para analizar tu tono de piel y tus colores.';

  @override
  String get readingColours => 'Analizando tus colores…';

  @override
  String get yourSeason => 'Tu estación';

  @override
  String get seasonLightSpring => 'Primavera clara';

  @override
  String get seasonTrueSpring => 'Primavera pura';

  @override
  String get seasonBrightSpring => 'Primavera brillante';

  @override
  String get seasonLightSummer => 'Verano claro';

  @override
  String get seasonTrueSummer => 'Verano puro';

  @override
  String get seasonSoftSummer => 'Verano suave';

  @override
  String get seasonSoftAutumn => 'Otoño suave';

  @override
  String get seasonTrueAutumn => 'Otoño puro';

  @override
  String get seasonDarkAutumn => 'Otoño profundo';

  @override
  String get seasonDarkWinter => 'Invierno profundo';

  @override
  String get seasonTrueWinter => 'Invierno puro';

  @override
  String get seasonBrightWinter => 'Invierno brillante';

  @override
  String get adviceLightSpring =>
      'Te favorecen los colores frescos y delicados: melocotón, coral y aguamarina cálida.';

  @override
  String get adviceTrueSpring =>
      'Te favorecen los colores vivos y soleados: amapola, amarillo dorado y turquesa.';

  @override
  String get adviceBrightSpring =>
      'Te favorecen los colores intensos y cálidos: coral vivo, limón y azul celeste.';

  @override
  String get adviceLightSummer =>
      'Te favorecen los pasteles ligeros: azul empolvado, lavanda y rosa.';

  @override
  String get adviceTrueSummer =>
      'Te favorecen los colores fríos y suaves: azul pizarra, frambuesa y verde azulado suave.';

  @override
  String get adviceSoftSummer =>
      'Te favorecen los colores apagados y ahumados: rosa empolvado, salvia y azul grisáceo.';

  @override
  String get adviceSoftAutumn =>
      'Te favorecen los colores tierra apagados: caqui, musgo y topo cálido.';

  @override
  String get adviceTrueAutumn =>
      'Te favorecen los colores tierra intensos: óxido, oliva, mostaza y verde azulado.';

  @override
  String get adviceDarkAutumn =>
      'Te favorecen los colores cálidos y profundos: chocolate, verde bosque y naranja tostado.';

  @override
  String get adviceDarkWinter =>
      'Te favorecen los colores fríos y profundos: burdeos, verde pino y azul marino oscuro.';

  @override
  String get adviceTrueWinter =>
      'Te favorecen los colores fríos y nítidos: rojo puro, azul real y esmeralda.';

  @override
  String get adviceBrightWinter =>
      'Te favorecen los colores intensos y helados: fucsia, cobalto y blanco puro.';

  @override
  String colourFacts(String undertone, String depth, String contrast) {
    String _temp0 = intl.Intl.selectLogic(undertone, {
      'warm': 'cálido',
      'cool': 'frío',
      'other': 'neutro',
    });
    String _temp1 = intl.Intl.selectLogic(depth, {
      'light': 'claro',
      'deep': 'profundo',
      'other': 'medio',
    });
    String _temp2 = intl.Intl.selectLogic(contrast, {
      'high': 'alto',
      'low': 'bajo',
      'other': 'medio',
    });
    return 'Subtono $_temp0 · colorido $_temp1 · contraste $_temp2';
  }

  @override
  String get coloursSuit => 'Colores que te favorecen';

  @override
  String get coloursNeutrals => 'Tus neutros';

  @override
  String get coloursGoEasy => 'Úsalos con moderación';

  @override
  String get coloursUnclear =>
      'La foto no era clara, así que esto es un punto de partida. Un selfie con luz de día, mirando al frente, funciona mejor.';

  @override
  String get wardrobeTitle => 'Mi armario';

  @override
  String get wardrobeLine =>
      'Pronto podrás añadir tu propia ropa y tus conjuntos la usarán.';

  @override
  String get colourFailed => 'Esta vez no pudimos analizar tus colores.';

  @override
  String get colourPhotoProblem =>
      'No pudimos leer tu cara en esta foto. Funciona mejor un primer plano, mirando al frente y con luz de día.';

  @override
  String get colourNoCredit =>
      'Por ahora no se pueden hacer más análisis de color.';

  @override
  String get colourUnavailable =>
      'El análisis de color aún no está disponible en esta versión.';
}
