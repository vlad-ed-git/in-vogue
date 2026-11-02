# In Vogue

In Vogue is a Flutter app for Android and iOS that recommends women's outfits for the weather and occasion, then previews them on your photo with virtual try-on.

[Landing page](https://in-vogue-web.vercel.app/)

## How it works

Choose a full-body photo from your library, share your location, and sign in with Apple or Google. The app uses Open-Meteo forecasts to recommend outfits for today and tomorrow, taking your occasion, colour profile, and saved preferences into account. Each garment links to its retailer's product page.

An optional selfie adds a personal colour palette in Mirror. My Wardrobe lets you add outfits you own and receive weather-appropriate suggestions. Home-screen widgets show the day's weather and outfit. The app supports English, Spanish, and Simplified Chinese.

## Catalog

The catalog comes from Everlane's women's collection, retrieved through Shopify's Global Catalog and curated into 500 outfits. Product details and links are bundled in `assets/catalog/everlane_women.json`. Curated outfits are served from Firestore, with images in Firebase Storage; the app caches the catalog locally and refreshes it when its version changes.

Catalog preparation tools live in the separate workspace directory `../resources/tools/catalog/`. The repository's `scripts/export_catalog.py` exports the product data into the bundled asset.

## YouCam integration

YouCam runs only after sign-in, using photos selected from the device's library.

| API | Usage |
| --- | --- |
| AI Clothes Virtual Try-On V4 (`cloth-v4`) | Applies garments to the full-body photo in sequence, using each result as the next input. Completed outfit images are saved locally and in Firebase Storage for reuse. |
| AI Facial Color Tones Analyzer (`skin-tone-analysis`) | Reads colours from the optional selfie. The app maps those colours to a season and palette. Results are retained unless the user requests another analysis. |

The shared API client is in `lib/core/data/you_cam/`. Development builds bundle a local YouCam key; production builds currently have no key configured.

## Requirements and dependencies

| Tool | Version |
| --- | --- |
| Flutter / Dart | Local toolchain: Flutter 3.47.7 / Dart 3.13.5; declared Dart requirement: `^3.12.2` |
| Xcode / CocoaPods (iOS) | 26.3 / 1.16.2 |
| Java (Android) | 17 |
| Python (setup scripts) | 3 |

Install the Android SDK for Android development, or Xcode on macOS for iOS. Supported devices: Android 7.0+ (API 24), iOS 15+; the iOS widget requires iOS 17+.

Core dependencies are `flutter_bloc` for state, `get_it` for dependency injection, `go_router` for navigation, Firebase Authentication/Firestore/Storage, Hive and SQLite for local data, `dio` for HTTP, and `home_widget`/`workmanager` for widgets and background updates. Version constraints are in [pubspec.yaml](pubspec.yaml); exact resolved versions are in [pubspec.lock](pubspec.lock).

## Install and run

Run from the repository root. Commands use the `flutter` shell alias for your Flutter SDK; define it in `~/.zshrc` if needed. Setup also requires the Firebase and FlutterFire CLIs, access to `in-vogue-dev`, and a YouCam API key.

```sh
zsh -ic 'flutter pub get'
zsh -ic 'flutter gen-l10n'
firebase login
scripts/configure_firebase.sh development
```

Save your YouCam API key in `secrets/youcam_api.txt`, then run:

```sh
python3 scripts/write_development_key.py
zsh -ic 'flutter run --flavor development -t lib/main_development.dart'
```

The key and generated native Firebase configuration files are git-ignored. Development uses app ID `com.invogue.app.dev` and Firebase project `in-vogue-dev`. On iOS, open `ios/Runner.xcworkspace` when working in Xcode.

## Checks

```sh
zsh -ic 'flutter analyze'
zsh -ic 'flutter test'
```

Tests use fakes and mocks; they do not call live YouCam or Firebase services.
