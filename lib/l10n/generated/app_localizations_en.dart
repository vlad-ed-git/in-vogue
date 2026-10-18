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
  String get tagline => 'Meet tomorrow’s weather in style';

  @override
  String get welcomeDescription =>
      'See yourself in an outfit picked for tomorrow’s weather, with a link to buy every piece.';

  @override
  String get useMyLocation => 'Use my location';

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

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String setupFolio(int step, int total) {
    return '$step / $total';
  }

  @override
  String get yourPicks => 'Your picks';

  @override
  String yourPicksCount(int count) {
    return 'Your picks · $count';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get before => 'Before';

  @override
  String get after => 'After';

  @override
  String get tabHome => 'Home';

  @override
  String get tabMakeup => 'Makeup';

  @override
  String get tabSettings => 'Settings';

  @override
  String temperatureSpoken(int temperature) {
    return '$temperature degrees';
  }

  @override
  String feelsLike(int temperature) {
    return 'Feels like $temperature°';
  }

  @override
  String weatherFrom(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': 'Rain after $time',
      'showers': 'Showers after $time',
      'drizzle': 'Drizzle after $time',
      'snow': 'Snow after $time',
      'storm': 'Storms after $time',
      'other': 'Strong wind after $time',
    });
    return '$_temp0';
  }

  @override
  String weatherUntil(String kind, String time) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': 'Rain until $time',
      'showers': 'Showers until $time',
      'drizzle': 'Drizzle until $time',
      'snow': 'Snow until $time',
      'storm': 'Storms until $time',
      'other': 'Strong wind until $time',
    });
    return '$_temp0';
  }

  @override
  String weatherAllDay(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'rain': 'Rain all day',
      'showers': 'Showers all day',
      'drizzle': 'Drizzle all day',
      'snow': 'Snow all day',
      'storm': 'Storms all day',
      'other': 'Strong wind all day',
    });
    return '$_temp0';
  }

  @override
  String weatherSky(String sky) {
    String _temp0 = intl.Intl.selectLogic(sky, {
      'clear': 'Sunny',
      'partlyCloudy': 'Partly cloudy',
      'cloudy': 'Cloudy',
      'fog': 'Foggy',
      'other': 'Dry all day',
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
  String get weatherUnavailable => 'We couldn’t get the weather.';

  @override
  String weatherSaved(String savedAt) {
    return 'Showing the forecast saved on $savedAt.';
  }

  @override
  String get picksTitle => 'Pick a few you like';

  @override
  String picksLine(String heart) {
    return 'Tap $heart on a few pieces for this weather. We’ll learn your taste.';
  }

  @override
  String get heartSpoken => 'heart';

  @override
  String weatherSpoken(int temperature, String condition, int feelsLike) {
    return '$temperature degrees, $condition, feels like $feelsLike.';
  }

  @override
  String weatherSpokenWithDay(
    String day,
    int temperature,
    String condition,
    int feelsLike,
  ) {
    return '$day, $temperature degrees, $condition, feels like $feelsLike.';
  }

  @override
  String get occasionWork => 'Work';

  @override
  String get occasionCasual => 'Casual';

  @override
  String get occasionGoingOut => 'Going out';

  @override
  String get occasionStayingIn => 'Staying in';

  @override
  String get occasionWorkKicker => 'Workday';

  @override
  String get occasionCasualKicker => 'Casual';

  @override
  String get occasionGoingOutKicker => 'Going out';

  @override
  String get occasionStayingInKicker => 'Staying in';

  @override
  String get change => 'Change';

  @override
  String dayIs(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': 'Today is',
      'other': 'Tomorrow is',
    });
    return '$_temp0';
  }

  @override
  String get gettingOutfitReady => 'Getting your outfit ready…';

  @override
  String get tryOnFailed =>
      'We couldn’t dress you this time. Your photo is fine.';

  @override
  String get locationOff => 'In Vogue needs your location for the weather.';

  @override
  String get locationUnavailable => 'We couldn’t find where you are.';

  @override
  String get openSettings => 'Open settings';

  @override
  String offlineSaved(String savedAt) {
    return 'You’re offline. This is the outfit saved on $savedAt.';
  }

  @override
  String savedAt(String date, String time) {
    return '$date at $time';
  }

  @override
  String get photoUnreadable =>
      'We couldn’t open this photo. Choose another one.';

  @override
  String get photoTooSmall => 'This photo is too small. Choose a larger one.';

  @override
  String get photoUnusable => 'We can’t use this photo. Choose another one.';

  @override
  String get photoConverted =>
      'We changed this photo’s format so it works. Don’t like it? Choose another.';

  @override
  String get addPhotoOfYou => 'Add a photo of you';

  @override
  String get bodyPhotoWhy => 'We dress this photo in each outfit.';

  @override
  String get chooseDifferentPhoto => 'Choose a different photo';

  @override
  String get chooseFromPhotos => 'Choose from Photos';

  @override
  String get chooseFromGallery => 'Choose from Gallery';

  @override
  String get continueAction => 'Continue';

  @override
  String get example => 'Example';

  @override
  String get yourPhoto => 'Your photo';

  @override
  String get photoPasses => 'Your photo works';

  @override
  String get photoHeadToToe => 'Head to toe';

  @override
  String get photoStanding => 'Standing, facing forward';

  @override
  String get photoGoodLight => 'Good light';

  @override
  String get photoJustYou => 'Just you';

  @override
  String get photoCloseUp => 'Close up';

  @override
  String get photoFacingForward => 'Facing forward';

  @override
  String get photoDaylight => 'Daylight';

  @override
  String get photoHairOff => 'Hair off your face';

  @override
  String get bodyPhotoPrivacy =>
      'Your photo is only used to dress you in outfits. You can replace it any time.';

  @override
  String get exampleBodySpoken =>
      'Example: a woman photographed head to toe, facing forward, in even light';

  @override
  String get exampleFaceSpoken =>
      'Example: a face photographed close up, facing forward, in daylight';

  @override
  String get otherOutfitsPreparing => 'Other outfits are on their way.';

  @override
  String get otherOutfitsLocked => 'Other outfits come with Pro.';

  @override
  String get goPro => 'Go Pro';

  @override
  String outfitTileSpoken(int index, int count) {
    return 'Outfit $index of $count';
  }

  @override
  String outfitTileShownSpoken(int index, int count) {
    return 'Outfit $index of $count, shown';
  }

  @override
  String get lockedSpoken => 'Part of Pro';

  @override
  String planFree(int outfits, int looks) {
    String _temp0 = intl.Intl.pluralLogic(
      outfits,
      locale: localeName,
      other: '$outfits outfits',
      one: '1 outfit',
      zero: 'no outfits',
    );
    String _temp1 = intl.Intl.pluralLogic(
      looks,
      locale: localeName,
      other: '$looks makeup looks',
      one: '1 makeup look',
      zero: 'no makeup looks',
    );
    return 'Free plan · $_temp0 and $_temp1 left';
  }

  @override
  String get planNoOutfits => 'Free plan · no outfits left';

  @override
  String planMakeupLeft(int looks) {
    String _temp0 = intl.Intl.pluralLogic(
      looks,
      locale: localeName,
      other: '$looks makeup looks',
      one: '1 makeup look',
      zero: 'no makeup looks',
    );
    return 'Free plan · $_temp0 left';
  }

  @override
  String get onProList => 'On the Pro list ✓';

  @override
  String loveSpoken(String name) {
    return 'Love $name';
  }

  @override
  String get loved => 'Loved';

  @override
  String get loveThisColour => 'Love this colour';

  @override
  String colourCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count colours',
      one: '1 colour',
    );
    return '$_temp0';
  }

  @override
  String moreColours(int count) {
    return '+$count';
  }

  @override
  String get proceed => 'Proceed';

  @override
  String get done => 'Done';

  @override
  String buyAt(String brand) {
    return 'Buy at $brand';
  }

  @override
  String noLongerAvailable(String brand) {
    return 'No longer available at $brand';
  }

  @override
  String catalogPhotoSpoken(String name, String colour) {
    return '$name in $colour, catalogue photo';
  }

  @override
  String get preparing => 'Preparing';

  @override
  String faceAfterStep(int step) {
    return 'Your face after step $step';
  }

  @override
  String get faceWithLook => 'Your face with the finished look';

  @override
  String get facePhotoSpoken => 'Your face photo';

  @override
  String get logOut => 'Log out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get proName => 'In Vogue Pro';

  @override
  String get proLine => 'More outfits, more choice, makeup for all of them.';

  @override
  String get proBenefitDaily => 'A new outfit every day';

  @override
  String get proBenefitChoice => 'Other outfits to choose from';

  @override
  String get proBenefitCollection => 'The whole collection to browse';

  @override
  String get proBenefitMakeup => 'Makeup for every outfit';

  @override
  String get proPrice => '\$7.99 a month · or \$59.99 a year';

  @override
  String get onTheList => 'You’re on the list.';

  @override
  String get proSoon => 'Pro opens soon, and you’ll be the first to know.';

  @override
  String get backToInVogue => 'Back to In Vogue';

  @override
  String get widgetStepHold => 'Press and hold your home screen';

  @override
  String get widgetStepPlus => 'Tap +';

  @override
  String get widgetStepChoose => 'Choose In Vogue';

  @override
  String get widgetGettingReady => 'Getting ready';

  @override
  String widgetSaved(String when) {
    return 'Saved $when';
  }

  @override
  String get signInWithApple => 'Sign in with Apple';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInLine =>
      'Your photo and picks come with you. Then we make your first outfit.';

  @override
  String get signInFailed => 'We couldn’t sign you in. Please try again.';

  @override
  String get aboutYouTitle => 'What should we call you?';

  @override
  String get yourName => 'Your name';

  @override
  String get facePhotoTitle => 'Add a face photo';

  @override
  String get facePhotoLine => 'Optional. It makes your makeup match you.';

  @override
  String get addWidgetTitle => 'Add In Vogue to your home screen';

  @override
  String get addWidgetLine =>
      'Tomorrow’s weather and your outfit, without opening the app.';

  @override
  String get addToHomeScreen => 'Add to home screen';

  @override
  String get skip => 'Skip';

  @override
  String get widgetStepsTitle => 'Three steps on iPhone';

  @override
  String get widgetAddByHand =>
      'Add it from your home screen: press and hold, tap Widgets, choose In Vogue.';

  @override
  String widgetPreviewSpoken(String weather) {
    return '$weather Your outfit is getting ready.';
  }

  @override
  String get tryOnPhotoProblem =>
      'We couldn’t dress this photo. A different one may work.';

  @override
  String get tryOnNoCredit => 'No more outfits can be made for now.';

  @override
  String get tryOnUnavailable =>
      'Outfits aren’t available in this version yet.';

  @override
  String get shop => 'Shop';

  @override
  String get shopThisOutfit => 'Shop this outfit';

  @override
  String get aboutThisOutfit => 'About this outfit';

  @override
  String tryOnPiece(int piece, int pieces) {
    return 'Piece $piece of $pieces';
  }

  @override
  String outfitPhotoSpoken(String about) {
    return 'You, head to toe, in your outfit. $about';
  }

  @override
  String get noPicks => 'You haven’t picked anything yet.';

  @override
  String get removePickTitle => 'Remove from your picks?';

  @override
  String get remove => 'Remove';

  @override
  String get keep => 'Keep';

  @override
  String get outfitsTab => 'Outfits';

  @override
  String get weatherHot => 'Hot';

  @override
  String get weatherWarm => 'Warm';

  @override
  String get weatherMild => 'Mild';

  @override
  String get weatherCool => 'Cool';

  @override
  String get weatherCold => 'Cold';

  @override
  String get weatherRain => 'Rain';

  @override
  String feelsLikeFrom(int low) {
    return 'Feels like $low° and up';
  }

  @override
  String feelsLikeRange(int low, int high) {
    return 'Feels like $low–$high°';
  }

  @override
  String feelsLikeBelow(int high) {
    return 'Feels like below $high°';
  }

  @override
  String get waterResistantPieces => 'Water-resistant pieces';

  @override
  String get edit => 'Edit';

  @override
  String get replace => 'Replace';

  @override
  String get add => 'Add';

  @override
  String get save => 'Save';

  @override
  String signedInWith(String method) {
    String _temp0 = intl.Intl.selectLogic(method, {
      'apple': 'Signed in with Apple',
      'other': 'Signed in with Google',
    });
    return '$_temp0';
  }

  @override
  String get bodyPhoto => 'Body photo';

  @override
  String get bodyPhotoUse => 'Used to dress you';

  @override
  String get facePhoto => 'Face photo';

  @override
  String get facePhotoUse => 'Used for makeup';

  @override
  String get notAdded => 'Not added yet';

  @override
  String get membership => 'Membership';

  @override
  String get planPro => 'Pro';

  @override
  String get planFreeName => 'Free plan';

  @override
  String get location => 'Location';

  @override
  String locationWhileUsing(String city) {
    return '$city, while using the app';
  }

  @override
  String get locationNotSet => 'Not set';

  @override
  String get defaultDay => 'Default day';

  @override
  String get homeScreenWidget => 'Home-screen widget';

  @override
  String get defaultDayTomorrow => 'Tomorrow, today from 6 to 9 am';

  @override
  String get defaultDayTitle => 'Home opens on';

  @override
  String get deleteAccountTitle => 'Delete your account?';

  @override
  String get deleteAccountLine =>
      'Your profile, photos, picks and outfits will be deleted. You’ll confirm with Apple or Google. This can’t be undone.';

  @override
  String get keepAccount => 'Keep my account';

  @override
  String get makeupFailed =>
      'We couldn’t make your makeup this time. Your photo is fine.';

  @override
  String get makeupPhotoProblem =>
      'We couldn’t find your face in this photo. A close-up, facing forward in daylight, works best.';

  @override
  String get makeupNoCredit => 'No more makeup looks can be made for now.';

  @override
  String get makeupUnavailable => 'Makeup isn’t available in this version yet.';

  @override
  String makeupFor(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': 'Makeup for today',
      'other': 'Makeup for tomorrow',
    });
    return '$_temp0';
  }

  @override
  String get makeupStepsArriving => 'Your steps appear as each one is ready.';

  @override
  String makeupStepCount(String count) {
    String _temp0 = intl.Intl.selectLogic(count, {
      'three': 'Three steps',
      'four': 'Four steps',
      'five': 'Five steps',
      'six': 'Six steps',
      'other': 'The steps',
    });
    return '$_temp0';
  }

  @override
  String cheekColour(String colour) {
    String _temp0 = intl.Intl.selectLogic(colour, {
      'soft_pink': 'Soft pink',
      'peach': 'Peach',
      'rose': 'Rose',
      'terracotta': 'Terracotta',
      'other': 'Soft',
    });
    return '$_temp0';
  }

  @override
  String lipColour(String colour) {
    String _temp0 = intl.Intl.selectLogic(colour, {
      'nude': 'nude',
      'rosy_nude': 'rosy-nude',
      'rose': 'rose',
      'terracotta': 'terracotta',
      'red': 'red',
      'berry': 'berry',
      'brick': 'brick-red',
      'other': 'soft',
    });
    return '$_temp0';
  }

  @override
  String lookSentence(String cheeks, String lips, String palette) {
    String _temp0 = intl.Intl.selectLogic(palette, {
      'warm': 'your warm neutrals',
      'cool': 'your cool neutrals',
      'mixed': 'your neutrals',
      'other': 'the colour you’re wearing',
    });
    return '$cheeks cheeks and $lips lips, to go with $_temp0.';
  }

  @override
  String get makeupWaitsForOutfit =>
      'Your makeup follows your outfit, which is on its way.';

  @override
  String makeupNeedsOutfit(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today': 'There’s no outfit for today to match yet.',
      'other': 'There’s no outfit for tomorrow to match yet.',
    });
    return '$_temp0';
  }

  @override
  String get yourLastLook => 'Your last look';

  @override
  String get makeupFacePhotoLine => 'Your makeup is made on your own face.';

  @override
  String get makeupShadesNeutral =>
      'For shades that match you, use a face photo taken in daylight, facing forward.';

  @override
  String get loading => 'Loading';
}
