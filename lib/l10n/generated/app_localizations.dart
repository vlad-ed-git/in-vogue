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
  /// **'Meet tomorrow’s weather in style'**
  String get tagline;

  /// No description provided for @welcomeDescription.
  ///
  /// In en, this message translates to:
  /// **'See yourself in an outfit picked for tomorrow’s weather, with a link to buy every piece.'**
  String get welcomeDescription;

  /// Welcome's button; asks for the phone's location.
  ///
  /// In en, this message translates to:
  /// **'Use my location'**
  String get useMyLocation;

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

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

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

  /// Weather that begins during the day; time is such as 3 pm.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, rain{Rain after {time}} showers{Showers after {time}} drizzle{Drizzle after {time}} snow{Snow after {time}} storm{Storms after {time}} other{Strong wind after {time}}}'**
  String weatherFrom(String kind, String time);

  /// Weather that stops during the day; time is such as 11 am.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, rain{Rain until {time}} showers{Showers until {time}} drizzle{Drizzle until {time}} snow{Snow until {time}} storm{Storms until {time}} other{Strong wind until {time}}}'**
  String weatherUntil(String kind, String time);

  /// Weather that lasts the whole day.
  ///
  /// In en, this message translates to:
  /// **'{kind, select, rain{Rain all day} showers{Showers all day} drizzle{Drizzle all day} snow{Snow all day} storm{Storms all day} other{Strong wind all day}}'**
  String weatherAllDay(String kind);

  /// A dry, calm day's sky.
  ///
  /// In en, this message translates to:
  /// **'{sky, select, clear{Sunny} partlyCloudy{Partly cloudy} cloudy{Cloudy} fog{Foggy} other{Dry all day}}'**
  String weatherSky(String sky);

  /// Such as Tomorrow, Thu 16 Oct · New York.
  ///
  /// In en, this message translates to:
  /// **'{day}, {date} · {place}'**
  String dayDatePlace(String day, String date, String place);

  /// Such as Tomorrow, Thu 16 Oct.
  ///
  /// In en, this message translates to:
  /// **'{day}, {date}'**
  String dayDate(String day, String date);

  /// No forecast could be fetched or found; shown with Try again.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t get the weather.'**
  String get weatherUnavailable;

  /// savedAt is a date and time such as Thu 16 Oct at 9:12 pm.
  ///
  /// In en, this message translates to:
  /// **'Showing the forecast saved on {savedAt}.'**
  String weatherSaved(String savedAt);

  /// Heading above the pieces for the day's weather.
  ///
  /// In en, this message translates to:
  /// **'Pick a few you like'**
  String get picksTitle;

  /// heart is replaced by a heart icon, or spoken as heartSpoken.
  ///
  /// In en, this message translates to:
  /// **'Tap {heart} on a few outfits you like. We’ll learn your taste.'**
  String picksLine(String heart);

  /// The heart icon, read aloud inside picksLine.
  ///
  /// In en, this message translates to:
  /// **'heart'**
  String get heartSpoken;

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

  /// No description provided for @changeOccasion.
  ///
  /// In en, this message translates to:
  /// **'Change occasion'**
  String get changeOccasion;

  /// Title of the occasion sheet.
  ///
  /// In en, this message translates to:
  /// **'{day, select, today{Today is} other{Tomorrow is}}'**
  String dayIs(String day);

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

  /// The phone could not find its position; shown with Try again.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t find where you are.'**
  String get locationUnavailable;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @savedAt.
  ///
  /// In en, this message translates to:
  /// **'{date} at {time}'**
  String savedAt(String date, String time);

  /// A chosen photo could not be read.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t open this photo. Choose another one.'**
  String get photoUnreadable;

  /// A chosen photo is smaller than the try-on or the skin analysis needs.
  ///
  /// In en, this message translates to:
  /// **'This photo is too small. Choose a larger one.'**
  String get photoTooSmall;

  /// A chosen photo could not be read or changed to a format that works.
  ///
  /// In en, this message translates to:
  /// **'We can’t use this photo. Choose another one.'**
  String get photoUnusable;

  /// Under a chosen photo that was converted to a format YouCam takes.
  ///
  /// In en, this message translates to:
  /// **'We changed this photo’s format so it works. Don’t like it? Choose another.'**
  String get photoConverted;

  /// Title of setup step 2.
  ///
  /// In en, this message translates to:
  /// **'Add a photo of you'**
  String get addPhotoOfYou;

  /// Why setup step 2 needs the photo.
  ///
  /// In en, this message translates to:
  /// **'We dress this photo in each outfit.'**
  String get bodyPhotoWhy;

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

  /// Screen-reader label of the check on a chosen photo.
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

  /// No description provided for @signInWithApple.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get signInWithApple;

  /// No description provided for @signInWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get signInWithGoogle;

  /// Title of setup step 4.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Under the sign-in title: what carries over, and what comes next.
  ///
  /// In en, this message translates to:
  /// **'Your photo and picks come with you. Then we make your first outfit.'**
  String get signInLine;

  /// No description provided for @signInFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t sign you in. Please try again.'**
  String get signInFailed;

  /// Title of setup step 5.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get aboutYouTitle;

  /// Label of the name field.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get yourName;

  /// No description provided for @facePhotoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a selfie'**
  String get facePhotoTitle;

  /// No description provided for @facePhotoLine.
  ///
  /// In en, this message translates to:
  /// **'Optional. It’s for your skin tone and colour analysis.'**
  String get facePhotoLine;

  /// Title of setup step 6.
  ///
  /// In en, this message translates to:
  /// **'Add In Vogue to your home screen'**
  String get addWidgetTitle;

  /// No description provided for @addWidgetLine.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s weather and your outfit, without opening the app.'**
  String get addWidgetLine;

  /// No description provided for @addToHomeScreen.
  ///
  /// In en, this message translates to:
  /// **'Add to home screen'**
  String get addToHomeScreen;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @widgetStepsTitle.
  ///
  /// In en, this message translates to:
  /// **'Three steps on iPhone'**
  String get widgetStepsTitle;

  /// Android setup, when the launcher cannot place the widget from the app.
  ///
  /// In en, this message translates to:
  /// **'Add it from your home screen: press and hold, tap Widgets, choose In Vogue.'**
  String get widgetAddByHand;

  /// The widget preview read aloud; weather is weatherSpokenWithDay.
  ///
  /// In en, this message translates to:
  /// **'{weather} Your outfit is getting ready.'**
  String widgetPreviewSpoken(String weather);

  /// The try-on service could not use the person's body photo.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t dress this photo. A different one may work.'**
  String get tryOnPhotoProblem;

  /// YouCam's units are spent; no outfit is made.
  ///
  /// In en, this message translates to:
  /// **'No more outfits can be made for now.'**
  String get tryOnNoCredit;

  /// This build has no access to the try-on service.
  ///
  /// In en, this message translates to:
  /// **'Outfits aren’t available in this version yet.'**
  String get tryOnUnavailable;

  /// The button under the outfit that opens the pieces to buy.
  ///
  /// In en, this message translates to:
  /// **'Shop'**
  String get shop;

  /// Title of the page listing the outfit's pieces.
  ///
  /// In en, this message translates to:
  /// **'Shop this outfit'**
  String get shopThisOutfit;

  /// Heading above the sentence on why the outfit suits the day.
  ///
  /// In en, this message translates to:
  /// **'About this outfit'**
  String get aboutThisOutfit;

  /// How far the try-on is: the piece being put on.
  ///
  /// In en, this message translates to:
  /// **'Piece {piece} of {pieces}'**
  String tryOnPiece(int piece, int pieces);

  /// Screen-reader label of the outfit photo, followed by the sentence about the outfit.
  ///
  /// In en, this message translates to:
  /// **'You, head to toe, in your outfit. {about}'**
  String outfitPhotoSpoken(String about);

  /// Your picks has no loved pieces.
  ///
  /// In en, this message translates to:
  /// **'You haven’t picked anything yet.'**
  String get noPicks;

  /// Title of the sheet that confirms unloving a piece.
  ///
  /// In en, this message translates to:
  /// **'Remove from your picks?'**
  String get removePickTitle;

  /// Confirms removing a piece from the picks.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// Keeps the piece in the picks.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get keep;

  /// Home's tab with the whole collection to pick from.
  ///
  /// In en, this message translates to:
  /// **'Outfits'**
  String get outfitsTab;

  /// Chip: pieces for hot weather.
  ///
  /// In en, this message translates to:
  /// **'Hot'**
  String get weatherHot;

  /// Chip: pieces for warm weather.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get weatherWarm;

  /// Chip: pieces for mild weather.
  ///
  /// In en, this message translates to:
  /// **'Mild'**
  String get weatherMild;

  /// Chip: pieces for cool weather.
  ///
  /// In en, this message translates to:
  /// **'Cool'**
  String get weatherCool;

  /// Chip: pieces for cold weather.
  ///
  /// In en, this message translates to:
  /// **'Cold'**
  String get weatherCold;

  /// Chip: outfits for freezing weather, below 0 °C feels-like.
  ///
  /// In en, this message translates to:
  /// **'Freezing'**
  String get weatherFreezing;

  /// Chip: pieces documented as water-resistant.
  ///
  /// In en, this message translates to:
  /// **'Rain'**
  String get weatherRain;

  /// The warmest group's range.
  ///
  /// In en, this message translates to:
  /// **'Feels like {low}° and up'**
  String feelsLikeFrom(int low);

  /// A group's range.
  ///
  /// In en, this message translates to:
  /// **'Feels like {low}–{high}°'**
  String feelsLikeRange(int low, int high);

  /// The coldest group's range.
  ///
  /// In en, this message translates to:
  /// **'Feels like below {high}°'**
  String feelsLikeBelow(int high);

  /// Line under the Rain chip; never call them waterproof.
  ///
  /// In en, this message translates to:
  /// **'Outfits for rainy days'**
  String get rainOutfits;

  /// Action that edits a setting.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Action that replaces a photo.
  ///
  /// In en, this message translates to:
  /// **'Replace'**
  String get replace;

  /// Action that adds a missing photo.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Saves an edited setting.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// How the person signed in.
  ///
  /// In en, this message translates to:
  /// **'{method, select, apple{Signed in with Apple} other{Signed in with Google}}'**
  String signedInWith(String method);

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Body photo'**
  String get bodyPhoto;

  /// What the body photo is for.
  ///
  /// In en, this message translates to:
  /// **'Used to dress you'**
  String get bodyPhotoUse;

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Face photo'**
  String get facePhoto;

  /// What the face photo is for.
  ///
  /// In en, this message translates to:
  /// **'Used for your colour analysis'**
  String get facePhotoUse;

  /// A photo that has not been added.
  ///
  /// In en, this message translates to:
  /// **'Not added yet'**
  String get notAdded;

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Membership'**
  String get membership;

  /// The Pro membership.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get planPro;

  /// The free membership.
  ///
  /// In en, this message translates to:
  /// **'Free plan'**
  String get planFreeName;

  /// Settings row.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// The saved place and when the app may read the location.
  ///
  /// In en, this message translates to:
  /// **'{city}, while using the app'**
  String locationWhileUsing(String city);

  /// No saved location.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get locationNotSet;

  /// Settings row: the day Home opens on.
  ///
  /// In en, this message translates to:
  /// **'Default day'**
  String get defaultDay;

  /// Settings row whose Add places the widget, for anyone who skipped setup's widget step.
  ///
  /// In en, this message translates to:
  /// **'Home-screen widget'**
  String get homeScreenWidget;

  /// Home opens on tomorrow, except early in the morning.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow, today from 6 to 9 am'**
  String get defaultDayTomorrow;

  /// Title of the default day sheet.
  ///
  /// In en, this message translates to:
  /// **'Home opens on'**
  String get defaultDayTitle;

  /// Title of the sheet that confirms deleting the account.
  ///
  /// In en, this message translates to:
  /// **'Delete your account?'**
  String get deleteAccountTitle;

  /// What deleting the account removes.
  ///
  /// In en, this message translates to:
  /// **'Your profile, photos, picks and outfits will be deleted. You’ll confirm with Apple or Google. This can’t be undone.'**
  String get deleteAccountLine;

  /// Closes the delete sheet without deleting.
  ///
  /// In en, this message translates to:
  /// **'Keep my account'**
  String get keepAccount;

  /// Read by screen readers on a control or slot that is working.
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// A photo YouCam refused because the face is turned, tilted, or tipped up or down.
  ///
  /// In en, this message translates to:
  /// **'Your face is turned or tilted in this photo. Choose one where you look straight ahead.'**
  String get photoLookStraight;

  /// A photo YouCam refused because the face is too small in it.
  ///
  /// In en, this message translates to:
  /// **'Your face is too small in this photo. Choose a closer one.'**
  String get photoMoveCloser;

  /// A photo YouCam refused because the face is cut off or not centred.
  ///
  /// In en, this message translates to:
  /// **'Part of your face is cut off in this photo. Choose one that shows your whole face.'**
  String get photoShowWholeFace;

  /// A photo YouCam refused because more than one person is in it.
  ///
  /// In en, this message translates to:
  /// **'There’s more than one person in this photo. Choose one of just you.'**
  String get photoOnlyYou;

  /// A body photo YouCam refused because the person isn’t standing, head to toe.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t see you standing in this photo. Choose one of you standing, head to toe.'**
  String get photoStandHeadToToe;

  /// The tab with the colours that suit the person, and their wardrobe.
  ///
  /// In en, this message translates to:
  /// **'Mirror'**
  String get tabMirror;

  /// Mirror, without a face photo: the heading above the selfie picker.
  ///
  /// In en, this message translates to:
  /// **'Find your colours'**
  String get selfieTitle;

  /// Mirror, without a face photo.
  ///
  /// In en, this message translates to:
  /// **'Add a selfie for your skin tone and colour analysis.'**
  String get selfieLine;

  /// Mirror, while the skin-tone analysis runs.
  ///
  /// In en, this message translates to:
  /// **'Reading your colours…'**
  String get readingColours;

  /// Kicker above the colour season.
  ///
  /// In en, this message translates to:
  /// **'Your season'**
  String get yourSeason;

  /// No description provided for @seasonLightSpring.
  ///
  /// In en, this message translates to:
  /// **'Light Spring'**
  String get seasonLightSpring;

  /// No description provided for @seasonTrueSpring.
  ///
  /// In en, this message translates to:
  /// **'True Spring'**
  String get seasonTrueSpring;

  /// No description provided for @seasonBrightSpring.
  ///
  /// In en, this message translates to:
  /// **'Bright Spring'**
  String get seasonBrightSpring;

  /// No description provided for @seasonLightSummer.
  ///
  /// In en, this message translates to:
  /// **'Light Summer'**
  String get seasonLightSummer;

  /// No description provided for @seasonTrueSummer.
  ///
  /// In en, this message translates to:
  /// **'True Summer'**
  String get seasonTrueSummer;

  /// No description provided for @seasonSoftSummer.
  ///
  /// In en, this message translates to:
  /// **'Soft Summer'**
  String get seasonSoftSummer;

  /// No description provided for @seasonSoftAutumn.
  ///
  /// In en, this message translates to:
  /// **'Soft Autumn'**
  String get seasonSoftAutumn;

  /// No description provided for @seasonTrueAutumn.
  ///
  /// In en, this message translates to:
  /// **'True Autumn'**
  String get seasonTrueAutumn;

  /// No description provided for @seasonDarkAutumn.
  ///
  /// In en, this message translates to:
  /// **'Dark Autumn'**
  String get seasonDarkAutumn;

  /// No description provided for @seasonDarkWinter.
  ///
  /// In en, this message translates to:
  /// **'Dark Winter'**
  String get seasonDarkWinter;

  /// No description provided for @seasonTrueWinter.
  ///
  /// In en, this message translates to:
  /// **'True Winter'**
  String get seasonTrueWinter;

  /// No description provided for @seasonBrightWinter.
  ///
  /// In en, this message translates to:
  /// **'Bright Winter'**
  String get seasonBrightWinter;

  /// No description provided for @adviceLightSpring.
  ///
  /// In en, this message translates to:
  /// **'Fresh, delicate colours suit you: peach, coral and warm aqua.'**
  String get adviceLightSpring;

  /// No description provided for @adviceTrueSpring.
  ///
  /// In en, this message translates to:
  /// **'Bright, sunny colours suit you: poppy, golden yellow and turquoise.'**
  String get adviceTrueSpring;

  /// No description provided for @adviceBrightSpring.
  ///
  /// In en, this message translates to:
  /// **'Vivid, warm colours suit you: hot coral, lemon and azure.'**
  String get adviceBrightSpring;

  /// No description provided for @adviceLightSummer.
  ///
  /// In en, this message translates to:
  /// **'Airy pastels suit you: powder blue, lavender and rose.'**
  String get adviceLightSummer;

  /// No description provided for @adviceTrueSummer.
  ///
  /// In en, this message translates to:
  /// **'Gentle, cool colours suit you: slate blue, raspberry and soft teal.'**
  String get adviceTrueSummer;

  /// No description provided for @adviceSoftSummer.
  ///
  /// In en, this message translates to:
  /// **'Muted, smoky colours suit you: dusty rose, sage and grey-blue.'**
  String get adviceSoftSummer;

  /// No description provided for @adviceSoftAutumn.
  ///
  /// In en, this message translates to:
  /// **'Muted, earthy colours suit you: khaki, moss and warm taupe.'**
  String get adviceSoftAutumn;

  /// No description provided for @adviceTrueAutumn.
  ///
  /// In en, this message translates to:
  /// **'Rich, earthy colours suit you: rust, olive, mustard and teal.'**
  String get adviceTrueAutumn;

  /// No description provided for @adviceDarkAutumn.
  ///
  /// In en, this message translates to:
  /// **'Deep, warm colours suit you: chocolate, forest green and burnt orange.'**
  String get adviceDarkAutumn;

  /// No description provided for @adviceDarkWinter.
  ///
  /// In en, this message translates to:
  /// **'Deep, cool colours suit you: burgundy, pine and deep navy.'**
  String get adviceDarkWinter;

  /// No description provided for @adviceTrueWinter.
  ///
  /// In en, this message translates to:
  /// **'Crisp, cool colours suit you: true red, royal blue and emerald.'**
  String get adviceTrueWinter;

  /// No description provided for @adviceBrightWinter.
  ///
  /// In en, this message translates to:
  /// **'Vivid, icy colours suit you: fuchsia, cobalt and pure white.'**
  String get adviceBrightWinter;

  /// Why the season: the undertone, depth and contrast read from the face.
  ///
  /// In en, this message translates to:
  /// **'{undertone, select, warm{Warm} cool{Cool} other{Neutral}} undertone · {depth, select, light{light} deep{deep} other{medium}} colouring · {contrast, select, high{high} low{low} other{medium}} contrast'**
  String colourFacts(String undertone, String depth, String contrast);

  /// No description provided for @coloursSuit.
  ///
  /// In en, this message translates to:
  /// **'Colours that suit you'**
  String get coloursSuit;

  /// No description provided for @coloursNeutrals.
  ///
  /// In en, this message translates to:
  /// **'Your neutrals'**
  String get coloursNeutrals;

  /// Heading above the colours that suit the person least.
  ///
  /// In en, this message translates to:
  /// **'Go easy on'**
  String get coloursGoEasy;

  /// No description provided for @coloursUnclear.
  ///
  /// In en, this message translates to:
  /// **'The photo wasn’t clear, so this is a starting point. A selfie in daylight, facing forward, reads better.'**
  String get coloursUnclear;

  /// No description provided for @wardrobeTitle.
  ///
  /// In en, this message translates to:
  /// **'My wardrobe'**
  String get wardrobeTitle;

  /// No description provided for @colourFailed.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t read your colours this time.'**
  String get colourFailed;

  /// No description provided for @colourPhotoProblem.
  ///
  /// In en, this message translates to:
  /// **'We couldn’t read your face in this photo. A close-up, facing forward in daylight, works best.'**
  String get colourPhotoProblem;

  /// No description provided for @colourNoCredit.
  ///
  /// In en, this message translates to:
  /// **'No more colour readings can be made for now.'**
  String get colourNoCredit;

  /// No description provided for @colourUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Colour readings aren’t available in this version yet.'**
  String get colourUnavailable;

  /// Offered in Settings after the face photo is replaced.
  ///
  /// In en, this message translates to:
  /// **'Redo your skin analysis?'**
  String get redoAnalysisTitle;

  /// No description provided for @redoAnalysisLine.
  ///
  /// In en, this message translates to:
  /// **'Your colours stay as they are: a new photo doesn’t change you. Redo the analysis to read them from this one.'**
  String get redoAnalysisLine;

  /// No description provided for @redoAnalysis.
  ///
  /// In en, this message translates to:
  /// **'Redo skin analysis'**
  String get redoAnalysis;

  /// No description provided for @keepColours.
  ///
  /// In en, this message translates to:
  /// **'Keep my colours'**
  String get keepColours;

  /// After a redone skin analysis.
  ///
  /// In en, this message translates to:
  /// **'Your colours are updated.'**
  String get coloursUpdated;

  /// Mirror, when the wardrobe is empty.
  ///
  /// In en, this message translates to:
  /// **'Add photos of outfits you own.'**
  String get wardrobeEmpty;

  /// The button on Mirror and the title of the screen it opens.
  ///
  /// In en, this message translates to:
  /// **'Add an outfit'**
  String get addOutfit;

  /// No description provided for @addOutfitLine.
  ///
  /// In en, this message translates to:
  /// **'A photo of an outfit you own, and what it’s for.'**
  String get addOutfitLine;

  /// The name the person gives an outfit they own.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get outfitName;

  /// No description provided for @outfitColours.
  ///
  /// In en, this message translates to:
  /// **'Colours'**
  String get outfitColours;

  /// No description provided for @outfitWeather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get outfitWeather;

  /// No description provided for @outfitOccasion.
  ///
  /// In en, this message translates to:
  /// **'Occasion'**
  String get outfitOccasion;

  /// No description provided for @saveOutfit.
  ///
  /// In en, this message translates to:
  /// **'Save to my wardrobe'**
  String get saveOutfit;

  /// No description provided for @removeOutfit.
  ///
  /// In en, this message translates to:
  /// **'Remove from my wardrobe'**
  String get removeOutfit;

  /// No description provided for @removeOutfitTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this outfit?'**
  String get removeOutfitTitle;

  /// No description provided for @colourBlack.
  ///
  /// In en, this message translates to:
  /// **'Black'**
  String get colourBlack;

  /// No description provided for @colourWhite.
  ///
  /// In en, this message translates to:
  /// **'White'**
  String get colourWhite;

  /// No description provided for @colourGrey.
  ///
  /// In en, this message translates to:
  /// **'Grey'**
  String get colourGrey;

  /// No description provided for @colourBeige.
  ///
  /// In en, this message translates to:
  /// **'Beige'**
  String get colourBeige;

  /// No description provided for @colourBrown.
  ///
  /// In en, this message translates to:
  /// **'Brown'**
  String get colourBrown;

  /// No description provided for @colourNavy.
  ///
  /// In en, this message translates to:
  /// **'Navy'**
  String get colourNavy;

  /// No description provided for @colourBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colourBlue;

  /// No description provided for @colourGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colourGreen;

  /// No description provided for @colourRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colourRed;

  /// No description provided for @colourPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colourPink;

  /// No description provided for @colourPurple.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colourPurple;

  /// No description provided for @colourYellow.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colourYellow;

  /// No description provided for @colourOrange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colourOrange;

  /// Several colours, or a print.
  ///
  /// In en, this message translates to:
  /// **'Mixed'**
  String get colourMixed;

  /// A palette colour's name, the nearest of a list of clothing colours.
  ///
  /// In en, this message translates to:
  /// **'{name, select, white{White} ivory{Ivory} cream{Cream} stone{Stone} beige{Beige} sand{Sand} camel{Camel} tan{Tan} taupe{Taupe} greige{Greige} lightGrey{Light grey} silver{Silver} grey{Grey} charcoal{Charcoal} black{Black} chocolate{Chocolate} espresso{Espresso} coffee{Coffee} brown{Brown} cinnamon{Cinnamon} rust{Rust} brick{Brick} terracotta{Terracotta} burntOrange{Burnt orange} orange{Orange} apricot{Apricot} peach{Peach} salmon{Salmon} coral{Coral} poppy{Poppy} red{Red} burgundy{Burgundy} wine{Wine} blush{Blush} orchid{Orchid} dustyRose{Dusty rose} mauve{Mauve} raspberry{Raspberry} berry{Berry} fuchsia{Fuchsia} hotPink{Hot pink} watermelon{Watermelon} lemon{Lemon} buttercup{Buttercup} mustard{Mustard} gold{Gold} ochre{Ochre} mint{Mint} sage{Sage} moss{Moss} olive{Olive} khaki{Khaki} leafGreen{Leaf green} lime{Lime} emerald{Emerald} jade{Jade} forestGreen{Forest green} pine{Pine} teal{Teal} deepTeal{Deep teal} turquoise{Turquoise} aqua{Aqua} skyBlue{Sky blue} powderBlue{Powder blue} periwinkle{Periwinkle} cornflower{Cornflower} denim{Denim} slateBlue{Slate blue} royalBlue{Royal blue} cobalt{Cobalt} azure{Azure} navy{Navy} midnight{Midnight} lavender{Lavender} lilac{Lilac} violet{Violet} purple{Purple} plum{Plum} aubergine{Aubergine} other{Colour}}'**
  String colourName(String name);

  /// No description provided for @tipSuits.
  ///
  /// In en, this message translates to:
  /// **'Wear it near your face: tops, shirts, knits and jackets.'**
  String get tipSuits;

  /// No description provided for @tipNeutrals.
  ///
  /// In en, this message translates to:
  /// **'A base that goes with your colours: trousers, skirts and coats.'**
  String get tipNeutrals;

  /// No description provided for @tipGoEasy.
  ///
  /// In en, this message translates to:
  /// **'Keep it away from your face, or wear it lower down: trousers and skirts.'**
  String get tipGoEasy;

  /// The link under the season on Mirror.
  ///
  /// In en, this message translates to:
  /// **'See your full analysis'**
  String get analysisLink;

  /// No description provided for @analysisTitle.
  ///
  /// In en, this message translates to:
  /// **'Your skin analysis'**
  String get analysisTitle;

  /// No description provided for @analysisRead.
  ///
  /// In en, this message translates to:
  /// **'Read from your photo'**
  String get analysisRead;

  /// No description provided for @featureSkin.
  ///
  /// In en, this message translates to:
  /// **'Skin'**
  String get featureSkin;

  /// No description provided for @featureHair.
  ///
  /// In en, this message translates to:
  /// **'Hair'**
  String get featureHair;

  /// No description provided for @featureBrows.
  ///
  /// In en, this message translates to:
  /// **'Brows'**
  String get featureBrows;

  /// No description provided for @featureEyes.
  ///
  /// In en, this message translates to:
  /// **'Eyes'**
  String get featureEyes;

  /// No description provided for @featureLips.
  ///
  /// In en, this message translates to:
  /// **'Lips'**
  String get featureLips;

  /// No description provided for @analysisUndertone.
  ///
  /// In en, this message translates to:
  /// **'Undertone'**
  String get analysisUndertone;

  /// No description provided for @analysisDepth.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get analysisDepth;

  /// No description provided for @analysisContrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get analysisContrast;

  /// What the undertone means for the person.
  ///
  /// In en, this message translates to:
  /// **'{undertone, select, warm{Warm: your skin leans golden, so warm, earthy and golden colours glow on you.} cool{Cool: your skin leans pink, so cool, crisp colours suit you.} other{Neutral: your skin sits between golden and pink, so you can wear both; your hair tips the balance.}}'**
  String undertoneAbout(String undertone);

  /// What the depth means for the person.
  ///
  /// In en, this message translates to:
  /// **'{depth, select, light{Light: your skin and hair are light, so lighter, softer colours keep you in focus.} deep{Deep: your colouring is deep, so rich, deep colours suit you.} other{Medium: your colouring sits in the middle, so mid-depth colours suit you best.}}'**
  String depthAbout(String depth);

  /// What the contrast means for the person.
  ///
  /// In en, this message translates to:
  /// **'{contrast, select, high{High: your hair stands out against your skin, so bold pairings suit you.} low{Low: your features blend softly, so tone-on-tone looks suit you.} other{Medium: your features contrast gently, so medium contrast works best.}}'**
  String contrastAbout(String contrast);

  /// No description provided for @analysisNote.
  ///
  /// In en, this message translates to:
  /// **'YouCam reads these colours from your photo. The season is our suggestion from them.'**
  String get analysisNote;

  /// Why the outfit suits a day that starts cold and warms up: the coldest and warmest feels-like and when.
  ///
  /// In en, this message translates to:
  /// **'{coldest}° at {coldTime}, {warmest}° by {warmTime}: the layer comes off as it warms up.'**
  String reasonLayerOff(
    int coldest,
    String coldTime,
    int warmest,
    String warmTime,
  );

  /// Why: no outfit suits both the coldest and the warmest hours.
  ///
  /// In en, this message translates to:
  /// **'Nothing in the catalog spans {coldest}° to {warmest}°: dressed for the coldest hours.'**
  String reasonNoSpan(int coldest, int warmest);

  /// Why: no outfit for the day is made for its rain or snow.
  ///
  /// In en, this message translates to:
  /// **'No outfit for today keeps out the rain or snow: take an umbrella.'**
  String get reasonNoWeatherMatch;

  /// Why: rain comes later in the day.
  ///
  /// In en, this message translates to:
  /// **'Rain from {time}: an outfit that takes the wet.'**
  String reasonRainFrom(String time);

  /// Why: rain from the start of the day.
  ///
  /// In en, this message translates to:
  /// **'Rain today: an outfit that takes the wet.'**
  String get reasonRainAllDay;

  /// Why: snow comes later in the day.
  ///
  /// In en, this message translates to:
  /// **'Snow from {time}: covered legs and warm layers.'**
  String reasonSnowFrom(String time);

  /// Why: snow from the start of the day.
  ///
  /// In en, this message translates to:
  /// **'Snow today: covered legs and warm layers.'**
  String get reasonSnowAllDay;

  /// Why: a freezing day.
  ///
  /// In en, this message translates to:
  /// **'Below freezing, {coldest}° at the coldest: a warm coat on top.'**
  String reasonFreezing(int coldest);

  /// Why: strong wind comes later in the day.
  ///
  /// In en, this message translates to:
  /// **'Wind from {time}: nothing the wind catches.'**
  String reasonWindFrom(String time);

  /// Why: strong wind from the start of the day.
  ///
  /// In en, this message translates to:
  /// **'Windy today: nothing the wind catches.'**
  String get reasonWindAllDay;

  /// Why: the occasion is staying in.
  ///
  /// In en, this message translates to:
  /// **'A day at home: something easy to wear.'**
  String get reasonHome;

  /// Why: the outfit suits the whole day's range.
  ///
  /// In en, this message translates to:
  /// **'Feels like {coldest}° to {warmest}° today: dressed for all of it.'**
  String reasonSteady(int coldest, int warmest);

  /// Why: the day feels the same throughout.
  ///
  /// In en, this message translates to:
  /// **'Feels like {coldest}° today: dressed for it.'**
  String reasonSteadyOne(int coldest);

  /// The reason, then the person's colour season, which chose the outfit's colours.
  ///
  /// In en, this message translates to:
  /// **'{reason} In your {season} colours.'**
  String reasonInSeason(String reason, String season);
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
