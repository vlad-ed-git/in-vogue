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
  String get tabHome => 'Home';

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
  String planFree(int outfits) {
    String _temp0 = intl.Intl.pluralLogic(
      outfits,
      locale: localeName,
      other: '$outfits outfits',
      one: '1 outfit',
      zero: 'no outfits',
    );
    return 'Free plan · $_temp0 left';
  }

  @override
  String get planNoOutfits => 'Free plan · no outfits left';

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
  String get logOut => 'Log out';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get proName => 'In Vogue Pro';

  @override
  String get proLine => 'More outfits, more choice.';

  @override
  String get proBenefitDaily => 'A new outfit every day';

  @override
  String get proBenefitChoice => 'Other outfits to choose from';

  @override
  String get proBenefitCollection => 'The whole collection to browse';

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
  String get facePhotoTitle => 'Add a selfie';

  @override
  String get facePhotoLine =>
      'Optional. It’s for your skin tone and colour analysis.';

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
  String get facePhotoUse => 'Used for your colour analysis';

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
  String get loading => 'Loading';

  @override
  String get photoLookStraight =>
      'Your face is turned or tilted in this photo. Choose one where you look straight ahead.';

  @override
  String get photoMoveCloser =>
      'Your face is too small in this photo. Choose a closer one.';

  @override
  String get photoShowWholeFace =>
      'Part of your face is cut off in this photo. Choose one that shows your whole face.';

  @override
  String get photoOnlyYou =>
      'There’s more than one person in this photo. Choose one of just you.';

  @override
  String get photoStandHeadToToe =>
      'We couldn’t see you standing in this photo. Choose one of you standing, head to toe.';

  @override
  String get tabMirror => 'Mirror';

  @override
  String get selfieTitle => 'Find your colours';

  @override
  String get selfieLine =>
      'Add a selfie for your skin tone and colour analysis.';

  @override
  String get readingColours => 'Reading your colours…';

  @override
  String get yourSeason => 'Your season';

  @override
  String get seasonLightSpring => 'Light Spring';

  @override
  String get seasonTrueSpring => 'True Spring';

  @override
  String get seasonBrightSpring => 'Bright Spring';

  @override
  String get seasonLightSummer => 'Light Summer';

  @override
  String get seasonTrueSummer => 'True Summer';

  @override
  String get seasonSoftSummer => 'Soft Summer';

  @override
  String get seasonSoftAutumn => 'Soft Autumn';

  @override
  String get seasonTrueAutumn => 'True Autumn';

  @override
  String get seasonDarkAutumn => 'Dark Autumn';

  @override
  String get seasonDarkWinter => 'Dark Winter';

  @override
  String get seasonTrueWinter => 'True Winter';

  @override
  String get seasonBrightWinter => 'Bright Winter';

  @override
  String get adviceLightSpring =>
      'Fresh, delicate colours suit you: peach, coral and warm aqua.';

  @override
  String get adviceTrueSpring =>
      'Bright, sunny colours suit you: poppy, golden yellow and turquoise.';

  @override
  String get adviceBrightSpring =>
      'Vivid, warm colours suit you: hot coral, lemon and azure.';

  @override
  String get adviceLightSummer =>
      'Airy pastels suit you: powder blue, lavender and rose.';

  @override
  String get adviceTrueSummer =>
      'Gentle, cool colours suit you: slate blue, raspberry and soft teal.';

  @override
  String get adviceSoftSummer =>
      'Muted, smoky colours suit you: dusty rose, sage and grey-blue.';

  @override
  String get adviceSoftAutumn =>
      'Muted, earthy colours suit you: khaki, moss and warm taupe.';

  @override
  String get adviceTrueAutumn =>
      'Rich, earthy colours suit you: rust, olive, mustard and teal.';

  @override
  String get adviceDarkAutumn =>
      'Deep, warm colours suit you: chocolate, forest green and burnt orange.';

  @override
  String get adviceDarkWinter =>
      'Deep, cool colours suit you: burgundy, pine and deep navy.';

  @override
  String get adviceTrueWinter =>
      'Crisp, cool colours suit you: true red, royal blue and emerald.';

  @override
  String get adviceBrightWinter =>
      'Vivid, icy colours suit you: fuchsia, cobalt and pure white.';

  @override
  String colourFacts(String undertone, String depth, String contrast) {
    String _temp0 = intl.Intl.selectLogic(undertone, {
      'warm': 'Warm',
      'cool': 'Cool',
      'other': 'Neutral',
    });
    String _temp1 = intl.Intl.selectLogic(depth, {
      'light': 'light',
      'deep': 'deep',
      'other': 'medium',
    });
    String _temp2 = intl.Intl.selectLogic(contrast, {
      'high': 'high',
      'low': 'low',
      'other': 'medium',
    });
    return '$_temp0 undertone · $_temp1 colouring · $_temp2 contrast';
  }

  @override
  String get coloursSuit => 'Colours that suit you';

  @override
  String get coloursNeutrals => 'Your neutrals';

  @override
  String get coloursGoEasy => 'Go easy on';

  @override
  String get coloursUnclear =>
      'The photo wasn’t clear, so this is a starting point. A selfie in daylight, facing forward, reads better.';

  @override
  String get wardrobeTitle => 'My wardrobe';

  @override
  String get colourFailed => 'We couldn’t read your colours this time.';

  @override
  String get colourPhotoProblem =>
      'We couldn’t read your face in this photo. A close-up, facing forward in daylight, works best.';

  @override
  String get colourNoCredit => 'No more colour readings can be made for now.';

  @override
  String get colourUnavailable =>
      'Colour readings aren’t available in this version yet.';

  @override
  String get redoAnalysisTitle => 'Redo your skin analysis?';

  @override
  String get redoAnalysisLine =>
      'Your colours stay as they are: a new photo doesn’t change you. Redo the analysis to read them from this one.';

  @override
  String get redoAnalysis => 'Redo skin analysis';

  @override
  String get keepColours => 'Keep my colours';

  @override
  String get coloursUpdated => 'Your colours are updated.';

  @override
  String get wardrobeEmpty => 'Add photos of outfits you own.';

  @override
  String get addOutfit => 'Add an outfit';

  @override
  String get addOutfitLine =>
      'A photo of an outfit you own, and what it’s for.';

  @override
  String get outfitName => 'Name';

  @override
  String get outfitColour => 'Colour';

  @override
  String get outfitWeather => 'Weather';

  @override
  String get outfitOccasion => 'Occasion';

  @override
  String get saveOutfit => 'Save to my wardrobe';

  @override
  String get removeOutfit => 'Remove from my wardrobe';

  @override
  String get removeOutfitTitle => 'Remove this outfit?';

  @override
  String get colourBlack => 'Black';

  @override
  String get colourWhite => 'White';

  @override
  String get colourGrey => 'Grey';

  @override
  String get colourBeige => 'Beige';

  @override
  String get colourBrown => 'Brown';

  @override
  String get colourNavy => 'Navy';

  @override
  String get colourBlue => 'Blue';

  @override
  String get colourGreen => 'Green';

  @override
  String get colourRed => 'Red';

  @override
  String get colourPink => 'Pink';

  @override
  String get colourPurple => 'Purple';

  @override
  String get colourYellow => 'Yellow';

  @override
  String get colourOrange => 'Orange';

  @override
  String get colourMixed => 'Mixed';

  @override
  String colourName(String name) {
    String _temp0 = intl.Intl.selectLogic(name, {
      'white': 'White',
      'ivory': 'Ivory',
      'cream': 'Cream',
      'stone': 'Stone',
      'beige': 'Beige',
      'sand': 'Sand',
      'camel': 'Camel',
      'tan': 'Tan',
      'taupe': 'Taupe',
      'greige': 'Greige',
      'lightGrey': 'Light grey',
      'silver': 'Silver',
      'grey': 'Grey',
      'charcoal': 'Charcoal',
      'black': 'Black',
      'chocolate': 'Chocolate',
      'espresso': 'Espresso',
      'coffee': 'Coffee',
      'brown': 'Brown',
      'cinnamon': 'Cinnamon',
      'rust': 'Rust',
      'brick': 'Brick',
      'terracotta': 'Terracotta',
      'burntOrange': 'Burnt orange',
      'orange': 'Orange',
      'apricot': 'Apricot',
      'peach': 'Peach',
      'salmon': 'Salmon',
      'coral': 'Coral',
      'poppy': 'Poppy',
      'red': 'Red',
      'burgundy': 'Burgundy',
      'wine': 'Wine',
      'blush': 'Blush',
      'orchid': 'Orchid',
      'dustyRose': 'Dusty rose',
      'mauve': 'Mauve',
      'raspberry': 'Raspberry',
      'berry': 'Berry',
      'fuchsia': 'Fuchsia',
      'hotPink': 'Hot pink',
      'watermelon': 'Watermelon',
      'lemon': 'Lemon',
      'buttercup': 'Buttercup',
      'mustard': 'Mustard',
      'gold': 'Gold',
      'ochre': 'Ochre',
      'mint': 'Mint',
      'sage': 'Sage',
      'moss': 'Moss',
      'olive': 'Olive',
      'khaki': 'Khaki',
      'leafGreen': 'Leaf green',
      'lime': 'Lime',
      'emerald': 'Emerald',
      'jade': 'Jade',
      'forestGreen': 'Forest green',
      'pine': 'Pine',
      'teal': 'Teal',
      'deepTeal': 'Deep teal',
      'turquoise': 'Turquoise',
      'aqua': 'Aqua',
      'skyBlue': 'Sky blue',
      'powderBlue': 'Powder blue',
      'periwinkle': 'Periwinkle',
      'cornflower': 'Cornflower',
      'denim': 'Denim',
      'slateBlue': 'Slate blue',
      'royalBlue': 'Royal blue',
      'cobalt': 'Cobalt',
      'azure': 'Azure',
      'navy': 'Navy',
      'midnight': 'Midnight',
      'lavender': 'Lavender',
      'lilac': 'Lilac',
      'violet': 'Violet',
      'purple': 'Purple',
      'plum': 'Plum',
      'aubergine': 'Aubergine',
      'other': 'Colour',
    });
    return '$_temp0';
  }

  @override
  String get tipSuits =>
      'Wear it near your face: tops, shirts, knits and jackets.';

  @override
  String get tipNeutrals =>
      'A base that goes with your colours: trousers, skirts and coats.';

  @override
  String get tipGoEasy =>
      'Keep it away from your face, or wear it lower down: trousers and skirts.';

  @override
  String get analysisLink => 'See your full analysis';

  @override
  String get analysisTitle => 'Your skin analysis';

  @override
  String get analysisRead => 'Read from your photo';

  @override
  String get featureSkin => 'Skin';

  @override
  String get featureHair => 'Hair';

  @override
  String get featureBrows => 'Brows';

  @override
  String get featureEyes => 'Eyes';

  @override
  String get featureLips => 'Lips';

  @override
  String get analysisUndertone => 'Undertone';

  @override
  String get analysisDepth => 'Depth';

  @override
  String get analysisContrast => 'Contrast';

  @override
  String undertoneAbout(String undertone) {
    String _temp0 = intl.Intl.selectLogic(undertone, {
      'warm':
          'Warm: your skin leans golden, so warm, earthy and golden colours glow on you.',
      'cool': 'Cool: your skin leans pink, so cool, crisp colours suit you.',
      'other':
          'Neutral: your skin sits between golden and pink, so you can wear both; your hair tips the balance.',
    });
    return '$_temp0';
  }

  @override
  String depthAbout(String depth) {
    String _temp0 = intl.Intl.selectLogic(depth, {
      'light':
          'Light: your skin and hair are light, so lighter, softer colours keep you in focus.',
      'deep': 'Deep: your colouring is deep, so rich, deep colours suit you.',
      'other':
          'Medium: your colouring sits in the middle, so mid-depth colours suit you best.',
    });
    return '$_temp0';
  }

  @override
  String contrastAbout(String contrast) {
    String _temp0 = intl.Intl.selectLogic(contrast, {
      'high':
          'High: your hair stands out against your skin, so bold pairings suit you.',
      'low': 'Low: your features blend softly, so tone-on-tone looks suit you.',
      'other':
          'Medium: your features contrast gently, so medium contrast works best.',
    });
    return '$_temp0';
  }

  @override
  String get analysisNote =>
      'YouCam reads these colours from your photo. The season is our suggestion from them.';
}
