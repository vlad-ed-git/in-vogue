import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'In Vogue'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Meet tomorrow’s weather in style.'**
  String get tagline;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'Outfits for your day. Makeup for your look.'**
  String get welcomeDescription;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @cacheFailure.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t save your changes. Please try again.'**
  String get cacheFailure;

  /// No description provided for @networkFailure.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. Please check your connection.'**
  String get networkFailure;

  /// No description provided for @serverFailure.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get serverFailure;

  /// No description provided for @startupFailure.
  ///
  /// In en, this message translates to:
  /// **'In Vogue couldn’t start. Please try again.'**
  String get startupFailure;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// Back bar action.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Close action on Go Pro.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Setup progress folio, such as 2 / 6.
  ///
  /// In en, this message translates to:
  /// **'{step} / {total}'**
  String setupFolio(int step, int total);

  /// Link to the loved pieces.
  ///
  /// In en, this message translates to:
  /// **'Your picks'**
  String get yourPicks;

  /// Count of loved pieces in the picks bar.
  ///
  /// In en, this message translates to:
  /// **'Your picks · {count}'**
  String yourPicksCount(int count);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @tomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get tomorrow;

  /// Makeup comparison: the face photo.
  ///
  /// In en, this message translates to:
  /// **'Before'**
  String get before;

  /// Makeup comparison: the finished look.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get after;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabMakeup.
  ///
  /// In en, this message translates to:
  /// **'Makeup'**
  String get tabMakeup;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// Screen-reader temperature.
  ///
  /// In en, this message translates to:
  /// **'{temperature} degrees'**
  String temperatureSpoken(int temperature);

  /// No description provided for @feelsLike.
  ///
  /// In en, this message translates to:
  /// **'Feels like {temperature}°'**
  String feelsLike(int temperature);

  /// Screen-reader weather sentence.
  ///
  /// In en, this message translates to:
  /// **'{temperature} degrees, {condition}, feels like {feelsLike}.'**
  String weatherSpoken(int temperature, String condition, int feelsLike);

  /// Screen-reader weather sentence with its day.
  ///
  /// In en, this message translates to:
  /// **'{day}, {temperature} degrees, {condition}, feels like {feelsLike}.'**
  String weatherSpokenWithDay(
    String day,
    int temperature,
    String condition,
    int feelsLike,
  );

  /// Occasion row in the Change sheet.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get occasionWork;

  /// Occasion row in the Change sheet.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get occasionCasual;

  /// Occasion row in the Change sheet.
  ///
  /// In en, this message translates to:
  /// **'Going out'**
  String get occasionGoingOut;

  /// Occasion row in the Change sheet.
  ///
  /// In en, this message translates to:
  /// **'Staying in'**
  String get occasionStayingIn;

  /// Occasion kicker, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Workday'**
  String get occasionWorkKicker;

  /// Occasion kicker, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Casual'**
  String get occasionCasualKicker;

  /// Occasion kicker, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Going out'**
  String get occasionGoingOutKicker;

  /// Occasion kicker, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Staying in'**
  String get occasionStayingInKicker;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Title of the occasion sheet.
  ///
  /// In en, this message translates to:
  /// **'{day, select, today{Today is} other{Tomorrow is}}'**
  String dayIs(String day);

  /// Credit under every photo of the user.
  ///
  /// In en, this message translates to:
  /// **'AI preview · Outfits by {brand}'**
  String aiPreviewCredit(String brand);

  /// Credit under a partner photo.
  ///
  /// In en, this message translates to:
  /// **'Outfits by {brand}'**
  String outfitsByCredit(String brand);

  /// No description provided for @gettingOutfitReady.
  ///
  /// In en, this message translates to:
  /// **'Getting your outfit ready…'**
  String get gettingOutfitReady;

  /// No description provided for @tryOnFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t dress you this time. Your photo is fine.'**
  String get tryOnFailed;

  /// No description provided for @locationOff.
  ///
  /// In en, this message translates to:
  /// **'In Vogue needs your location for the weather.'**
  String get locationOff;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// savedAt is a date and time such as Thu 16 Oct at 9:12 pm.
  ///
  /// In en, this message translates to:
  /// **'You’re offline. This is the outfit saved on {savedAt}.'**
  String offlineSaved(String savedAt);

  /// No description provided for @savedAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String savedAt(String date, String time);

  /// No description provided for @everyLookSeen.
  ///
  /// In en, this message translates to:
  /// **'{day, select, today{You’ve seen every outfit that suits today. New pieces arrive soon.} other{You’ve seen every outfit that suits tomorrow. New pieces arrive soon.}}'**
  String everyLookSeen(String day);

  /// No description provided for @notFullLength.
  ///
  /// In en, this message translates to:
  /// **'This photo doesn’t show you head to toe.'**
  String get notFullLength;

  /// No description provided for @chooseAnotherPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose another photo'**
  String get chooseAnotherPhoto;

  /// No description provided for @chooseDifferentPhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose a different photo'**
  String get chooseDifferentPhoto;

  /// iOS photo picker button.
  ///
  /// In en, this message translates to:
  /// **'Choose from Photos'**
  String get chooseFromPhotos;

  /// Android photo picker button.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// Kicker under an example photo, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Example'**
  String get example;

  /// Kicker under the chosen photo, shown in capitals.
  ///
  /// In en, this message translates to:
  /// **'Your photo'**
  String get yourPhoto;

  /// Screen-reader label of the check on a photo that passes.
  ///
  /// In en, this message translates to:
  /// **'Your photo works'**
  String get photoPasses;

  /// No description provided for @photoHeadToToe.
  ///
  /// In en, this message translates to:
  /// **'Head to toe'**
  String get photoHeadToToe;

  /// No description provided for @photoStanding.
  ///
  /// In en, this message translates to:
  /// **'Standing, facing forward'**
  String get photoStanding;

  /// No description provided for @photoGoodLight.
  ///
  /// In en, this message translates to:
  /// **'Good light'**
  String get photoGoodLight;

  /// No description provided for @photoJustYou.
  ///
  /// In en, this message translates to:
  /// **'Just you'**
  String get photoJustYou;

  /// No description provided for @photoCloseUp.
  ///
  /// In en, this message translates to:
  /// **'Close up'**
  String get photoCloseUp;

  /// No description provided for @photoFacingForward.
  ///
  /// In en, this message translates to:
  /// **'Facing forward'**
  String get photoFacingForward;

  /// No description provided for @photoDaylight.
  ///
  /// In en, this message translates to:
  /// **'Daylight'**
  String get photoDaylight;

  /// No description provided for @photoHairOff.
  ///
  /// In en, this message translates to:
  /// **'Hair off your face'**
  String get photoHairOff;

  /// No description provided for @bodyPhotoPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Your photo is only used to dress you in outfits. You can replace it any time.'**
  String get bodyPhotoPrivacy;

  /// No description provided for @exampleBodySpoken.
  ///
  /// In en, this message translates to:
  /// **'Example: a woman photographed head to toe, facing forward, in even light'**
  String get exampleBodySpoken;

  /// No description provided for @exampleFaceSpoken.
  ///
  /// In en, this message translates to:
  /// **'Example: a face photographed close up, facing forward, in daylight'**
  String get exampleFaceSpoken;

  /// No description provided for @otherOutfitsPreparing.
  ///
  /// In en, this message translates to:
  /// **'Other outfits are on their way.'**
  String get otherOutfitsPreparing;

  /// No description provided for @otherOutfitsLocked.
  ///
  /// In en, this message translates to:
  /// **'Other outfits come with Pro.'**
  String get otherOutfitsLocked;

  /// No description provided for @goPro.
  ///
  /// In en, this message translates to:
  /// **'Go Pro'**
  String get goPro;

  /// No description provided for @outfitTileSpoken.
  ///
  /// In en, this message translates to:
  /// **'Outfit {index} of {count}'**
  String outfitTileSpoken(int index, int count);

  /// No description provided for @outfitTileShownSpoken.
  ///
  /// In en, this message translates to:
  /// **'Outfit {index} of {count}, shown'**
  String outfitTileShownSpoken(int index, int count);

  /// No description provided for @lockedSpoken.
  ///
  /// In en, this message translates to:
  /// **'Part of Pro'**
  String get lockedSpoken;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free plan · {outfits, plural, =0{no outfits} =1{1 outfit} other{{outfits} outfits}} and {looks, plural, =0{no makeup looks} =1{1 makeup look} other{{looks} makeup looks}} left'**
  String planFree(int outfits, int looks);

  /// No description provided for @planNoOutfits.
  ///
  /// In en, this message translates to:
  /// **'Free plan · no outfits left'**
  String get planNoOutfits;

  /// No description provided for @planMakeupLeft.
  ///
  /// In en, this message translates to:
  /// **'Free plan · {looks, plural, =0{no makeup looks} =1{1 makeup look} other{{looks} makeup looks}} left'**
  String planMakeupLeft(int looks);

  /// No description provided for @onProList.
  ///
  /// In en, this message translates to:
  /// **'On the Pro list ✓'**
  String get onProList;

  /// No description provided for @loveSpoken.
  ///
  /// In en, this message translates to:
  /// **'Love {name}'**
  String loveSpoken(String name);

  /// No description provided for @loved.
  ///
  /// In en, this message translates to:
  /// **'Loved'**
  String get loved;

  /// No description provided for @loveThisColour.
  ///
  /// In en, this message translates to:
  /// **'Love this colour'**
  String get loveThisColour;

  /// No description provided for @colourCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 colour} other{{count} colours}}'**
  String colourCount(int count);

  /// No description provided for @moreColours.
  ///
  /// In en, this message translates to:
  /// **'+{count}'**
  String moreColours(int count);

  /// No description provided for @proceed.
  ///
  /// In en, this message translates to:
  /// **'Proceed'**
  String get proceed;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @buyAt.
  ///
  /// In en, this message translates to:
  /// **'Buy at {brand}'**
  String buyAt(String brand);

  /// No description provided for @noLongerAvailable.
  ///
  /// In en, this message translates to:
  /// **'No longer available at {brand}'**
  String noLongerAvailable(String brand);

  /// No description provided for @catalogPhotoSpoken.
  ///
  /// In en, this message translates to:
  /// **'{name} in {colour}, catalogue photo'**
  String catalogPhotoSpoken(String name, String colour);

  /// No description provided for @preparing.
  ///
  /// In en, this message translates to:
  /// **'Preparing'**
  String get preparing;

  /// No description provided for @faceAfterStep.
  ///
  /// In en, this message translates to:
  /// **'Your face after step {step}'**
  String faceAfterStep(int step);

  /// No description provided for @faceWithLook.
  ///
  /// In en, this message translates to:
  /// **'Your face with the finished look'**
  String get faceWithLook;

  /// No description provided for @facePhotoSpoken.
  ///
  /// In en, this message translates to:
  /// **'Your face photo'**
  String get facePhotoSpoken;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @proName.
  ///
  /// In en, this message translates to:
  /// **'In Vogue Pro'**
  String get proName;

  /// No description provided for @proLine.
  ///
  /// In en, this message translates to:
  /// **'More outfits, more choice, makeup for all of them.'**
  String get proLine;

  /// No description provided for @proBenefitDaily.
  ///
  /// In en, this message translates to:
  /// **'A new outfit every day'**
  String get proBenefitDaily;

  /// No description provided for @proBenefitChoice.
  ///
  /// In en, this message translates to:
  /// **'Other outfits to choose from'**
  String get proBenefitChoice;

  /// No description provided for @proBenefitCollection.
  ///
  /// In en, this message translates to:
  /// **'The whole collection to browse'**
  String get proBenefitCollection;

  /// No description provided for @proBenefitMakeup.
  ///
  /// In en, this message translates to:
  /// **'Makeup for every outfit'**
  String get proBenefitMakeup;

  /// The only price in the app.
  ///
  /// In en, this message translates to:
  /// **'\$7.99 a month · or \$59.99 a year'**
  String get proPrice;

  /// No description provided for @onTheList.
  ///
  /// In en, this message translates to:
  /// **'You’re on the list.'**
  String get onTheList;

  /// No description provided for @proSoon.
  ///
  /// In en, this message translates to:
  /// **'Pro opens soon, and you’ll be the first to know.'**
  String get proSoon;

  /// No description provided for @backToInVogue.
  ///
  /// In en, this message translates to:
  /// **'Back to In Vogue'**
  String get backToInVogue;

  /// No description provided for @widgetStepHold.
  ///
  /// In en, this message translates to:
  /// **'Press and hold your home screen'**
  String get widgetStepHold;

  /// No description provided for @widgetStepPlus.
  ///
  /// In en, this message translates to:
  /// **'Tap +'**
  String get widgetStepPlus;

  /// No description provided for @widgetStepChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose In Vogue'**
  String get widgetStepChoose;

  /// Home-screen widget before the first outfit.
  ///
  /// In en, this message translates to:
  /// **'Getting ready'**
  String get widgetGettingReady;

  /// Home-screen widget date line when the snapshot is stale.
  ///
  /// In en, this message translates to:
  /// **'Saved {when}'**
  String widgetSaved(String when);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
