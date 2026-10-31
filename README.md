# In Vogue

In Vogue is a weather app for women on Android and iPhone. It picks an outfit for the forecast and your plans, then shows it on your own photo using YouCam's AI Clothes Virtual Try-On. An optional selfie, read by YouCam's AI Facial Color Tones Analyzer, steers the outfits toward colours that suit you. Every piece links to its product page.

The catalog is Everlane's women's collection, curated into 500 outfits. Rights to the catalog and brand content are in place. The app is for women aged 16 and older and was built for the [YouCam API Skin AI & eCommerce VTO Hackathon](https://youcam-api-skin-ai-ecommerce.devpost.com).

- Outfits for today and tomorrow, chosen from the hourly forecast and the day's occasion: work, casual, going out or staying in.
- Virtual try-on on your full-body photo, with a link to buy each piece.
- A colour season and palette from an optional selfie, on the Mirror tab.
- My wardrobe: photos of outfits you own, suggested when they suit the day.
- Home-screen widgets on Android and iPhone.
- English, Spanish and Simplified Chinese.

## How YouCam is used

| API | Task | Used for | Units |
| --- | --- | --- | --- |
| AI Clothes Virtual Try-On V4 | `cloth-v4` | Dressing the body photo in an outfit, one garment per task | 2 per garment |
| AI Facial Color Tones Analyzer | `skin-tone-analysis` | Reading skin, hair, brow, eye and lip colours from the selfie | 20, once per person |

All calls go through one client in `lib/core/data/you_cam/` (API v2.0), and only after sign-in.

- **Try-on** (`MakeOutfit`, `TryOnRepositoryImpl`). The body photo is uploaded through the File API. Each garment is then added in turn, each pass starting from the previous result: bottoms, then the top, then outerwear. A dress is a single full-body pass. The app polls each task and downloads the final image straight away, because result links expire after about two hours. It saves the image on the device and in Firebase Storage, then deletes the YouCam tasks. An interrupted outfit resumes from the last finished garment, and an outfit already made for the same photo is reused.
- **Colour analysis** (`AnalyseFace`). The selfie is uploaded as a PNG of at most 1024 px and analysed once per person. YouCam returns colours, not a season. `SeasonRules` turns them into one of 12 colour seasons and a palette.

Photo errors, such as a turned face, are shown as plain advice on what to change. YouCam doesn't charge for failed tasks.

## Tech stack

- Flutter and Dart, with feature-first Clean Architecture under `lib/features/`
- flutter_bloc and bloc_concurrency for state, get_it for dependency injection, go_router for navigation, dartz for errors
- Firebase: Authentication (Sign in with Apple and Google), Cloud Firestore and Cloud Storage
- Hive and sqflite for local storage, dio for HTTP
- Open-Meteo for forecasts; geolocator and geocoding for location
- home_widget and workmanager, with a Kotlin widget on Android and a SwiftUI WidgetKit widget on iPhone
- flutter_localizations and intl, with ARB files in `lib/l10n/arb/`
- flutter_test, bloc_test, mockito, mocktail, fake_cloud_firestore, sqflite_common_ffi and http_mock_adapter for tests

## Requirements

- Flutter 3.44 or newer (Dart 3.12.2 or newer)
- Xcode 26 and CocoaPods 1.16 for iOS
- The Android SDK and Java 17 for Android
- The Firebase CLI and FlutterFire CLI, to generate the native Firebase files
- Python 3, for the scripts in `scripts/`
- Access to the Firebase projects, and a YouCam API key

The app runs on iOS 15.0 or later (the widget needs iOS 17.0) and Android 7.0 (API 24) or later.

## Flavors and entry points

| Flavor | Entry point | App ID | Firebase project |
| --- | --- | --- | --- |
| development | `lib/main_development.dart` | `com.invogue.app.dev` | `in-vogue-dev` |
| production | `lib/main_production.dart` | `com.invogue.app` | `in-vogue` |

Both entry points call `lib/main_init.dart`. It checks that the flavor matches its Firebase project, then starts Firebase, Hive, SQLite and dependency injection. Development builds bundle the YouCam key; production builds don't include one yet. `flutter run` without arguments uses development.

## Getting started

```sh
flutter pub get
flutter gen-l10n
scripts/configure_firebase.sh development
```

`configure_firebase.sh` writes the git-ignored `google-services.json` and `GoogleService-Info.plist` for the flavor.

To make outfits and read colours in development builds, put a YouCam key in `secrets/youcam_api.txt` (git-ignored) and run:

```sh
python3 scripts/write_development_key.py
```

Without a key the app still runs, but it makes no outfits and reads no colours.

## Commands

| Task | Command |
| --- | --- |
| Run development | `flutter run --flavor development -t lib/main_development.dart` |
| Run production | `flutter run --flavor production -t lib/main_production.dart` |
| Generate localizations | `flutter gen-l10n` |
| Generate mocks | `dart run build_runner build --delete-conflicting-outputs` |
| Format | `dart format lib test integration_test` |
| Analyze | `flutter analyze` |
| Unit and widget tests | `flutter test` |
| Release builds (iOS archive and Android APK) | `scripts/build_release.sh development` or `production` |

VS Code launch configurations for both flavors are in `.vscode/`. Tests never call YouCam or a real Firebase project.

## Troubleshooting

**iOS native configuration.** After changing the iOS minimum deployment target or regenerating native dependencies, regenerate the configuration for both flavors before you open or run the app in Xcode:

```sh
flutter build ios --config-only --debug --flavor development -t lib/main_development.dart
flutter build ios --config-only --debug --flavor production -t lib/main_production.dart
```

This updates Flutter's generated `FlutterGeneratedPluginSwiftPackage` manifest. Don't edit that manifest directly, because Flutter regenerates it.

**`SourcePackages/cloud_firestore-<version>" failed: No such file or directory (2)`.** Create the missing folder, then build again:

```sh
mkdir -p build/ios/SourcePackages
```

**Opening the project in Xcode.** Open `ios/Runner.xcworkspace`, not `Runner.xcodeproj`. If `pod install` rewrites `ios/Runner.xcodeproj/project.pbxproj` in an older format, keep the version Xcode saved.

**Google sign-in fails on Android.** Add the SHA-1 of the key that signed the build to the flavor's Android app in Firebase, then run `scripts/configure_firebase.sh` again.
