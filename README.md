# In Vogue

A Flutter mobile app for outfits matched to tomorrow’s weather. This first slice
provides native flavors, Firebase initialization, local persistence, localization,
and a working language picker. Onboarding, weather, outfits, makeup, auth, and
widgets are the next product work.

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

Plain `flutterN run` defaults to development. Explicit commands:

```sh
flutterN run --flavor development -t lib/main_development.dart
flutterN run --flavor production -t lib/main_production.dart
```

VS Code launch configurations select the matching flavor and entrypoint. On iOS,
open `ios/Runner.xcworkspace`; generate the matching configuration with the CLI
before running directly from Xcode. A mismatched entrypoint/flavor fails startup
before initializing Firebase or storage.

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

## Architecture

```text
lib/
  app/                     # Bootstrap and MaterialApp composition
  core/
    config/                # Environment identity and validation
    domain/                # Pure Dart languages, failures, use-case contracts
    data/                  # Local diagnostic implementation
    persistence/           # Hive key/value store and SQLite cache
    di/                    # Initialized core resources and disposal
    ui/                    # Shared theme and starter/error surfaces
    utils/                 # context.translated, Either and locale helpers
  features/preferences/
    domain/                # Repository contract and language use cases
    data/                  # Local source and repository implementation
    presentation/bloc/     # Serial language updates and failure state
    di/                    # Feature registrations
  l10n/arb/                # English source, Spanish and Simplified Chinese
  l10n/generated/          # Generated, checked-in translations
  main_init.dart           # Firebase → local stores → DI → saved language
```

Domain code has no Flutter, Firebase, Hive, or SQLite imports. Repositories return
`Either<Failure, T>`; infrastructure exceptions are translated at their boundaries.
Presentation converts failures into localized messages. GetIt is used at composition
and DI boundaries; widgets receive their BLoC rather than resolving repositories.

Hive stores the selected language. SQLite provides a versioned, disposable text
cache with expiry; it is not the authoritative outfit ledger. Both stores are
isolated by flavor and closed by `GetIt.reset()` in tests. Keep private images,
provider keys, and auth tokens out of this generic cache.

`context.translated.tagline`, `context.color`, and `context.txtTheme` follow the
Utano style. English is the explicit initial default, regardless of device locale.
The saved choice loads before the first app frame. Rapid changes are serialized;
failed writes retain the previous language and show a localized message. Current
themes follow the system; location/daylight theme scheduling comes with weather.
Commissioner/Newsreader fonts, final icons, and product screens remain design work.

## Verify

Everyday checks are fast and need no native build:

```sh
flutterN gen-l10n
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test integration_test
flutterN analyze
flutterN test --coverage
```

Native builds take minutes. Rely on the checks above while working, and run
these once when a task is complete, unless a native change truly needs one sooner:

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
expiry/upserts, complete ARB catalogs, UI language switching/failure recovery, and
320px screens at 200% text in both themes. The device integration test additionally
initializes real native Firebase/Hive/SQLite and reloads persisted preferences.
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
