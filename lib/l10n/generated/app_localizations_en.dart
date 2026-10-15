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
  String everyLookSeen(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      'today':
          'You’ve seen every outfit that suits today. New pieces arrive soon.',
      'other':
          'You’ve seen every outfit that suits tomorrow. New pieces arrive soon.',
    });
    return '$_temp0';
  }

  @override
  String get notFullLength => 'This photo doesn’t show you head to toe.';

  @override
  String get chooseAnotherPhoto => 'Choose another photo';

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
}
