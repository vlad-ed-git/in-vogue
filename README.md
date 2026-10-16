# In Vogue

A Flutter mobile app for outfits matched to tomorrow’s weather. It has native
flavors, Firebase initialization, local persistence, localization, the design
system and the six-screen setup flow: Welcome (location), Your photo, tomorrow’s
weather with pieces to pick, Sign in, About you and the home-screen widget.
Sign-in is Sign in with Apple (on Apple platforms only) and Google, through
Firebase Auth. The widget runs behind a contract whose stand-in says plainly
that it is not available yet. Settings has the language row; Home, Makeup and
the rest of Settings are next.

## Run

Open **`weather-dot-me/in-vogue`** as the project. Use **`flutterN`** on this
machine; the alias is loaded by an interactive zsh (`zsh -ic 'flutterN …'`).
Validated toolchain: Flutter **3.44.4**, Dart **3.12.2**, Xcode **26.3**,
CocoaPods **1.16.2**, Java **17**. iOS deployment target: **15.0**.

```sh
flutterN pub get
flutterN gen-l10n
flutterN run
```


### iOS native configuration

Plugins are linked with CocoaPods (`enable-swift-package-manager: false` in
`pubspec.yaml`); always open `ios/Runner.xcworkspace`, not the project.
`flutterN run` and `flutterN build ios` run `pod install` when plugins change.
To run from Xcode, first generate the flavor's configuration:

```sh
flutterN build ios --config-only --debug --flavor development -t lib/main_development.dart
flutterN build ios --config-only --debug --flavor production -t lib/main_production.dart
```

`pod install` may save `ios/Runner.xcodeproj/project.pbxproj` in an older file
format (object version 54 instead of Xcode's 60). Only the formatting changes;
keep the Xcode-saved version.

Plain `flutterN run` defaults to development. Explicit commands:

```sh
flutterN run --flavor development -t lib/main_development.dart \
  --dart-define-from-file=secrets/development.json
flutterN run --flavor production -t lib/main_production.dart
```

### The YouCam key (development only)

Try-ons call YouCam from the app for now. The key is read only by the
development entrypoint, from the git-ignored `secrets/development.json`;
the production entrypoint never reads it, and a build without it makes no
outfits. Create the file from `secrets/youcam_api.txt`:

```sh
python3 scripts/write_development_defines.py
```

The development launch configuration passes it. Every try-on pass costs 2
units: the Firestore document `usage/youcam` (`unitsSpent`, `unitLimit` 15)
reserves them before each call and gives them back when YouCam charges
nothing, and no try-on starts past the limit. Tests never call YouCam.

VS Code launch configurations select the matching flavor and entrypoint. A
mismatched entrypoint/flavor fails startup before initializing Firebase or
storage.

| Flavor | Package / bundle ID | Firebase project | Launcher name |
| --- | --- | --- | --- |
| development | `com.invogue.app.dev` | `in-vogue-dev` | In Vogue Dev |
| production | `com.invogue.app` | `in-vogue` | In Vogue |

## Firebase on a new checkout

The generated Dart **client configuration** is committed. Native Google Services
JSON/plist files are intentionally ignored, so restore them before a native build:

```sh
firebase login
scripts/configure_firebase.sh development
scripts/configure_firebase.sh production
```

Requires Firebase CLI, FlutterFire CLI, and the `xcodeproj` Ruby gem (provided by
CocoaPods). The script configures both platforms and all Debug/Profile/Release
iOS configurations. The Android plugin selects `src/<flavor>/google-services.json`;
iOS copies only `flavors/<flavor>/GoogleService-Info.plist` into the app. Ordinary
builds use the local files and do not require the FlutterFire CLI.

Separate entrypoints follow the [FlutterFire flavor guide](https://codewithandrea.com/articles/flutter-firebase-multiple-flavors-flutterfire-cli/)
and Flutter’s [Android](https://docs.flutter.dev/deployment/flavors) and
[iOS](https://docs.flutter.dev/deployment/flavors-ios) flavor configuration.
No backend rules, functions, auth providers, or paid API calls are deployed by setup.

### Firestore and Storage rules

`firestore.rules` and `storage.rules` let each person read and write only
`users/{uid}/**` (uploads: images under 10 MB), and let signed-in people
reserve units in `usage/youcam` without passing or changing its limit.
Deploy them to development with an admin service account:

```sh
GOOGLE_APPLICATION_CREDENTIALS=secrets/<service-account>.json \
  firebase deploy --only firestore:rules,storage --project in-vogue-dev
```

### Sign-in prerequisites

- Firebase Auth: the Apple and Google providers enabled; each Android signing
  key's SHA-1 added to the flavor's Android app, then the native files
  refreshed with `scripts/configure_firebase.sh <flavor>`.
- iOS, in Xcode (Runner target): the team, the **Sign in with Apple**
  capability, and a URL type with each flavor's `REVERSED_CLIENT_ID` from its
  `GoogleService-Info.plist` (Google Sign-In fails without it).
- Sign in with Apple is offered on Apple platforms only, so it needs no
  Services ID or key.

## Architecture

```text
lib/
  app/                     # Bootstrap and MaterialApp.router composition
    router/                # go_router routes, setup resume, tab shell, screens
  core/
    config/                # Environment identity and validation
    domain/                # Pure Dart languages, failures, use-case contracts
    data/                  # Local diagnostic implementation
    persistence/           # Hive key/value store and SQLite cache
    di/                    # Initialized core resources and disposal
    presentation/          # Design system: tokens, theme, shared widgets
    network/               # Server and network exceptions
    ui/                    # Startup-failure screen
    utils/                 # context.translated, failure messages, locales
  features/                # Each: domain/ data/ presentation/ di/
    setup/                 # Saved setup step and the six setup screens
    location/              # Coarse location (geolocator, geocoding)
    weather/               # Open-Meteo through dio, day rules, header
    photos/                # System photo picker and private photo store
    catalog/               # Bundled collection and picks
    auth/                  # Sign in with Apple and Google, Firebase Auth
    account/               # The setup saved on users/{uid} and in Storage
    outfits/               # Choosing, trying on and recording outfits
    profile/               # The person's name
    home_widget/           # Placing the home-screen widget
    preferences/           # Language
    settings/              # Settings tab
  l10n/arb/                # English source, Spanish and Simplified Chinese
  l10n/generated/          # Generated, checked-in translations
  main_init.dart           # Firebase → local stores → DI → saved language
```

Domain code has no Flutter, Firebase, Hive, or SQLite imports. Repositories return
`Either<Failure, T>`; infrastructure exceptions are translated at their boundaries.
Presentation converts failures into localized messages. GetIt is used at composition
and DI boundaries; widgets receive their BLoC rather than resolving repositories.

Routes are go_router 18, which uses the new `material_ui` package internally;
every route gives an explicit `flutter/material` page so the app's theme styles
it. Setup routes nest, so the saved step reopens with the earlier screens beneath
it for Back.

Hive stores the language, the setup step, the location, picks, the name and photo
records. Photos themselves live in the app's support folder, saved by file name
because iOS moves app folders on updates. SQLite provides a versioned, disposable
text cache with expiry (forecasts for two days); it is not the authoritative
outfit ledger. Both stores are
isolated by flavor and closed by `GetIt.reset()` in tests. Keep private images,
provider keys, and auth tokens out of this generic cache.

`context.translated.tagline` and `context.color` follow the Utano style. English
is the explicit initial default, regardless of device locale. The saved choice
loads before the first app frame. Rapid changes are serialized;
failed writes retain the previous language and show a localized message.

## Design system

`lib/core/presentation/` implements the design spec in `../design-spec/`; import
`package:in_vogue/core/presentation/presentation.dart`.

- `tokens/`: colours, type, spacing, layout and motion as constants.
- `theme/`: `InVogueTheme.paper`, the only theme, and `InVogueTheme.builder`, which
  keeps the platform brightness light and caps text scaling at 200%. iOS sets
  `UIUserInterfaceStyle` to Light and Android has no night resources.
- `foundations/`: icons, text with highlight and underline, tap targets,
  `Pressable`, photos, swatches and layout helpers.
- `components/`: the spec's components, grouped by area.

Fonts are Sofia Sans and Sofia Sans Extra Condensed (variable, SIL OFL) in
`assets/fonts/`. Interface icons come from `phosphoricons_flutter` (Phosphor
Regular, plus the filled heart). Weather glyphs are drawn from the spec's Phosphor
path data so that rain and snow can animate drop by drop. Copy lives in the ARB
files; there are no partner credits in the UI. Tests compare tokens and glyph
paths with `../design-spec/` when it is present beside this repository.

Launcher icons are generated from `../design-spec/assets/logo/`:

```sh
scripts/generate_app_icons.sh
```

## Verify

Everyday checks are fast and need no native build:

```sh
flutterN gen-l10n
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test integration_test
flutterN analyze
flutterN test --coverage
```

Tests follow each package's own documented way of testing it: platform-interface
mocks with `MockPlatformInterfaceMixin` for the plugins, `withClock` for time,
bloc_test's `MockBloc` for screens, sqflite_common_ffi for SQLite and
http_mock_adapter for dio. Where a package documents nothing, the tests cover our
code around it.

The picks collection and the knowledge base's outfits are bundled from
`../resources/`:

```sh
python3 scripts/export_catalog.py
python3 scripts/export_outfits.py
```

Native builds take minutes and run only when the owner asks; the owner's
device runs are the native check. For reference:

```sh
flutterN build apk --debug --flavor development -t lib/main_development.dart
flutterN build apk --debug --flavor production -t lib/main_production.dart
flutterN build ios --simulator --debug --flavor development -t lib/main_development.dart
flutterN build ios --simulator --debug --flavor production -t lib/main_production.dart

flutterN test integration_test/startup_test.dart --flavor development -d <simulator-id>
```

Tests cover Firebase/environment isolation, iOS flavor wiring (bundle IDs, display
names, xcconfigs and default entrypoints), English fallback and language restore,
Mockito repository failures, BLoC ordering, real Hive reopen/isolation, real SQLite
expiry/upserts, complete ARB catalogs, UI language switching/failure recovery,
320px screens at 200% text whatever the phone's appearance, the design tokens,
theme and every design-system widget, and the launcher icon sets. For setup they
cover the routes and resuming at the saved step, each of the six screens, the
location, forecast and day-weather rules, photo picking and keeping, the bundled
collection and picks, and the sign-in, name and widget contracts. The device
integration test additionally initializes real native Firebase/Hive/SQLite and
reloads persisted preferences.
Use a test installation: it changes the language and clears its disposable cache.
Verification is local. Do not add Git-hosted workflows or CI/CD setup; this is an explicit owner requirement.

Development release APKs can use the debug key for demos. Production releases
remain unsigned until you create the ignored `android/key.properties` (see
`android/key.properties.example`) pointing to your release keystore. iOS device
signing and TestFlight distribution require the owner’s Apple team/provisioning
and remain separate from simulator/debug build verification.

## Workspace references

The resumable product/engineering checkpoint is **`../checkpoint.md`**. Existing
catalog, knowledge base, and their Python tools live under **`../resources/`** and
are not part of the Flutter package or this app-local Git repository. Utano was
studied as a read-only reference; its data and credentials were not copied.
