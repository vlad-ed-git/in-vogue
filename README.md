# In Vogue

In Vogue is a weather app for Android and iPhone. Each day it shows the person, head to toe, wearing a real outfit from a partner fashion house, chosen for that day's weather and plans. It reads the person's colours from a selfie and shows the clothing colours that suit them, a link to buy every piece, and a home-screen widget. The current partner catalog is Everlane's women's collection; rights to the catalog and brand content are in place.

**Status (October 18, 2026):** an MVP for testers on the development flavor. Analyze is clean and 880 tests pass. Rules for AI agents working on the code are in [AGENTS.md](AGENTS.md).

## Contents

- [What it does](#what-it-does)
- [System design](#system-design)
- [Architecture](#architecture)
- [APIs and services](#apis-and-services)
- [Data](#data)
- [Getting started](#getting-started)
- [Commands](#commands)
- [Testing](#testing)
- [Security and privacy](#security-and-privacy)
- [Roadmap](#roadmap)

## What it does

**Setup** is six screens, and the app reopens on the one the person left:

1. **Welcome:** the logo, "Use my location" (approximate location only) and a language choice.
2. **Your photo:** a full-body photo from Photos or Gallery. There is no camera.
3. **Tomorrow's weather**, with a few pieces to heart.
4. **Sign in** with Apple (iPhone only) or Google.
5. **About you:** the person's name (filled in when Apple, Google or an old account knows it) and an optional face photo.
6. **Add the widget:** on Android the launcher's own "Add to home screen?" dialog places it, or the step says how where the launcher can't; iPhone shows the three steps.

Nothing leaves the phone before sign-in, and YouCam is called only after it.

**Home** shows the city and *Your picks* at the top, then a Today / Tomorrow / Outfits switch (tap or swipe). Below it come the weather that matters (temperature, feels-like, when rain starts, strong wind) and the occasion (Work, Casual, Going out, Staying in) with Change. Then the person wearing the day's outfit, revealed with a curtain, or "Getting your outfit ready… Piece n of N", or why it failed with Try again. Under the outfit are Shop and "About this outfit". The Outfits view lists the whole collection by weather, with hearts.

- **The day rule:** Home opens on tomorrow, except from 06:00 to 08:59, when it opens on today. A setting can make it always today.
- **Occasions:** Work from Monday to Friday and Casual at the weekend, by default. A changed occasion stays with its own date.

**Shop** lists every piece of the outfit with its photo, colour, name and material, and "Buy at Everlane", which opens that exact item. There are no prices. **Your picks** shows only the pieces the person loved; removing one asks first.

**Mirror** shows the person's colour season, why (undertone, depth and contrast) and its palette in round swatches: colours that suit them, their neutrals, and colours to go easy on. Tapping a swatch opens its name (the nearest of 78 clothing colours, `ColourNames`) and how to wear it. "See your full analysis" opens a sheet with the colours read from the photo (skin, hair, brows, eyes, lips), what the undertone, depth and contrast mean for the person, and the season. YouCam reads the colours from the face photo once per person: a new face photo keeps them, unless the person redoes the skin analysis from Settings. The season is In Vogue's own suggestion. Without a face photo, Mirror asks for a selfie for the skin tone and colour analysis, kept as soon as it is chosen; the face photo itself is shown only in Settings. My wardrobe sits below: the outfits the person owns in a grid, each opening its details (colours, weather, occasions) with Remove, and Add an outfit, which takes a photo from Photos or Gallery, a name, one or more colours, the weather it suits and its occasions. Home doesn't recommend from the wardrobe yet (owner to decide how).

**Settings** holds:
- the profile: face photo, name, how the person signed in, and Edit. Without a face photo, or when the photo can't be drawn, it shows the name's first letter on Rouge. Settings reloads its photos and profile whenever its tab is shown.
- the body and face photos. Replacing the face photo offers to redo the skin analysis; otherwise the colours stay.
- the membership (Pro or Free, shown only).
- the location, the default day and the language.
- the home-screen widget, whose Add places it, or says how.
- Log out, which also clears this account's outfit pictures, wardrobe photos and colour readings under way from the phone.
- Delete account, which removes the account's data from Firebase and from the phone.

**The home-screen widget** puts the day's weather on a Rouge slab beside the person in the day's outfit, in Small (weather only), Medium and Large. It picks the day as Home does and switches at 06:00, 09:00 and midnight. Until the outfit is made it shows the person's photo faded under "Getting ready", and when it has nothing newer it shows the time it was saved. A tap opens Home on that day and occasion. A background job refreshes it each morning, and Log out and Delete account clear it. On iPhone it is set up for the development flavor only, until production has its own App Group.

**Languages:** English (the default, whatever the phone's language), Spanish and Simplified Chinese, including the knowledge base's outfit reasons.

## System design

### The big picture

```
                ┌──────────────────── the phone: In Vogue (Flutter) ──────────────────────┐
Open-Meteo ◄────┤ weather: 3-day hourly forecast (dio), cached 2 days in SQLite            │
YouCam     ◄────┤ try-on · skin-tone analysis (after sign-in; key in dev builds)           │
Firebase   ◄────┤ Auth: Apple, Google · Firestore users/{uid}, errors · Storage, App Check │
Everlane   ◄────┤ "Buy at Everlane" opens the exact item (url_launcher)                    │
                │ bundled: catalog · 1,749 outfits                                         │
                │ home-screen widget: Kotlin (Android) · SwiftUI (iPhone, App Group)       │
                │ morning refresh: WorkManager (Android) · background app refresh (iPhone) │
                └──────────────────────────────────────────────────────────────────────────┘
On the Mac, offline: Shopify Global Catalog ─► resources/ (Python: catalog + knowledge base)
                     ─► in-vogue/scripts/export_*.py ─► in-vogue/assets/
```

Everything runs in the app; there are no servers or Cloud Functions. Each person's data lives under `users/{uid}` in Firestore and Storage, and the security rules let only that person reach it.

### Inside the app

```
main_development.dart ┐                        main_production.dart passes no YouCam key ─► stand-ins
main_production.dart  ┴► bootstrap ─► MainInit.init
   flavor ↔ Firebase check ─► Firebase + App Check ─► Hive + SQLite ─► core DI ─► 14 feature DIs
   ─► language + saved setup step (before the first frame) ─► InVogueApp ─► EnsureAccount
InVogueApp (MaterialApp.router, Paper theme only) ─► go_router (redirect: setup ⇄ tabs)
   ├─ /setup ► /photo ► /picks ► /sign-in ► /about-you ► /widget        (nested, so Back works)
   └─ tab shell (indexed stack; HomeBloc and the widget's sync above the tabs)
        ├─ /home      ─► Shop, Your picks (over the tabs)
        ├─ /mirror    ─► the colour season and palette, then My wardrobe
        └─ /settings
features/<name>/  presentation (BLoC, screens) ─► domain (pure Dart) ◄─ data (Firebase, Hive, dio, assets)
                  di/init.dart registers it all in GetIt
```

### Setup and the account

```
Welcome ─► Your photo ─► Weather + picks ─► Sign in ─────────────► About you ─► Add widget ─► Home
location   body photo    hearts             Apple | Google          name,         launcher or
                                            restore ─► save         selfie        three steps
├──────────── nothing leaves the phone ─────┤├──── account in Firebase; YouCam allowed from here ────┤
The step is saved in Hive; the app reopens on it with the earlier screens beneath for Back.
```

At sign-in the app first restores what the account has (the name, the face photo when the phone has none, and the favourites), then saves the phone's setup to it. Photos are replaced on the account only when their content changes. Favourites follow the account across phones: each save merges with what that phone last saved, so a piece unloved on one phone stays gone on the others. A new account is created on the Pro plan, and the rules stop anyone changing their own plan.

### A day's outfit

```
HomeBloc ─► FollowDay(day on screen), then FollowDay(other day)   (one claim at a time per phone)
FollowDay watches users/{uid}/days/{date}_{occasion} (phone's copy first):
  no record ─► ChooseOutfit (no refused pieces) ─► transaction: day = making(this phone) + suggestion recorded
  making, this phone, stopped ─► resume (Hive job, same photo, < 2 h)
  making, other phone ─► show its progress; unchanged 10 min ─► take over, same outfit
  ready ─► show the picture (phone copy, else Storage)      failed ─► reason + Try again
MakeOutfit, once the day is claimed:
  this photo + outfit tried on before? (tryOns: phone, then Firestore) ─► the day takes that picture at once
  else per piece (bottom ─► top ─► outer | dress ─► outer):
    write progress (stop if another phone took the day) ─► cloth-v4 (poll 5 s, ≤ 4 min)
  last piece ─► download ─► phone + Storage + tryOns ─► ready
  YouCam refused ─► failed for every phone      network or server error ─► stays making, resumes later
  a piece's photo refused ─► suggestion.refusedPiece ─► another outfit (≤ 3 per making), else failed
```

- **Choosing:** 1,749 outfits are bundled, sorted into 96 cells (a weather class combined with an occasion). Outfits never suggested come first, scored 80% on the knowledge base's rank and 20% on how many of their pieces the person loved; after that, the one suggested longest ago. Today and tomorrow never share an outfit, and a day keeps its outfit even if the forecast later moves it to another cell.
- **Claiming:** the day is claimed in one Firestore transaction, so two phones, or today and tomorrow, never clash. Another phone takes over a making that hasn't changed for 10 minutes.
- **Trying on:** YouCam dresses the person piece by piece, each pass on the last pass's picture, and progress is saved after each piece. An interrupted making resumes within 2 hours, while YouCam still holds the pictures.
- **Tried on once:** each finished picture is listed under the body photo's fingerprint and the outfit's signature, so a later day with the same photo and outfit takes the picture at once, with no YouCam call and no second upload. The fingerprint is the SHA-256 of the photo's bytes, which is the same on every phone; the photo's file name and URL aren't, because they come from a counter kept on each phone.

### Reading colours

```
ColoursBloc, when Mirror shows or a face photo is kept:
AnalyseFace: the person's reading on the account? (the colorProfiles doc saved last) ─► show it
  none yet ─► the face photo, upright PNG ≤ 1024 px ─► skin-tone-analysis, low strictness (20 units)
  poll 3 s, ≤ 2 min ─► colours (skin, brows, lips, hair, eyes) ─► colorProfiles/{sha256(face)}
  SeasonRules: undertone + depth + contrast ─► one of 12 seasons ─► its palette
  refused photo ─► what to change (PhotoAdvice) and Choose a different photo
Settings, face photo replaced ─► "Redo skin analysis?" ─► SkinAnalysisBloc ─► AnalyseFace(redo)
  a photo read before ─► its reading again, free; else a new analysis of the current photo
```

The analysis runs once per person (owner, October 18): a new face photo doesn't change who they are, so the reading stays until they redo it from Settings. Readings are kept under each photo's fingerprint, and the one saved last is the person's. One cut short is checked again rather than paid for twice (Hive `analysis_tasks`). YouCam only samples the colours; the season and palette are In Vogue's own, a suggestion.

### The home-screen widgets

```
HomeBloc ─► HomeWidgetSync ─► WidgetContentText (the person's language) ─► HomeWidgetBloc ─► PublishWidget
  ─► pictures shared (in place on Android; copied into the App Group on iPhone)
  ─► home_widget: 'in_vogue_widget' JSON (+ 'in_vogue_widget_refresh') ─► redraw
Android: InVogueWidgetProvider (Kotlin, RemoteViews), redrawn at 06:00 · 09:00 · 00:00 by scheduled updates
iPhone:  InVogueWidget (SwiftUI, WidgetKit), a timeline with entries at the same hours
Both: Home's day rule ─► Small | Medium | Large ─► tap: invogue://home?date&occasion&homeWidget ─► Home
Morning refresh, from 05:30: WorkManager (Android) · background app refresh (iPhone, when iOS allows)
  ─► widgetRefreshDispatcher ─► RefreshWidget: new weather + pictures already made (never YouCam)
```

The app writes today's and tomorrow's snapshots, their words already in the person's language, because the app's language isn't the phone's. The widget picks the day itself. On iPhone the extension can't read the app's files, so the app copies the day's pictures into the App Group's container, under names that change when a picture does. Publishes run one at a time, so two can't remove each other's pictures.

### Weather

The app asks Open-Meteo for a 3-day hourly forecast at the person's location and keeps it in SQLite for 2 days; offline, it shows the saved forecast with a note. Temperatures are in °F in the US and °C elsewhere. A day's *weather class* is the feels-like band of the occasion's window's coldest hour (hot, warm, mild, cool, cold), the precipitation (dry, wet, snow; snow only when cool or cold; drizzle counts as dry) and the wind (gusts of 39 km/h or more). That gives 24 classes, times 4 occasions, makes the 96 cells, keyed `band|precipitation|wind|context`, with 29 to 100 outfits each.

### What is kept where

| What | On the phone | On the account |
| --- | --- | --- |
| Forecasts | SQLite, 2 days | — |
| Days | Firestore's offline copy | `users/{uid}/days` |
| Outfit pictures | files in `outfits/{uid}/` | Storage `users/{uid}/days/` |
| Pictures made of a photo and outfit | `outfits/{uid}/made/` | `users/{uid}/tryOns` |
| Face colours | — | `users/{uid}/colorProfiles` |
| Unfinished try-ons | Hive `try_on_jobs`, resumed within 2 hours | the day's progress |
| Colour readings under way | Hive `analysis_tasks` | — |
| The wardrobe | photos in `wardrobe/{uid}/` | `users/{uid}/wardrobe`, Storage `users/{uid}/wardrobe/` |
| Photo fingerprints | memory, once per photo file | — |
| The widget's content | home_widget's storage (Android), the App Group (iPhone) | — |
| Error reports | memory, until someone signs in | `errors` |

### Rules worth knowing

- **Days:** `making`, then `ready` or `failed`. The lease is 10 minutes and a try-on job is valid for 2 hours.
- **Colours** (`SeasonRules`):
  - **Undertone** from the skin's CIELAB hue angle: warm from 60°, cool up to 52°, neutral between. A neutral skin leans warm with golden or copper hair (chroma from 12, hue 40–90°), cool with ash or black hair (chroma below 6), and otherwise warm from 56°.
  - **Depth** from the mean L* of skin and hair: light from 62, deep below 36 or when the skin's ITA° is below 12.
  - **Contrast** is the ΔL* between the skin and the darker of the brows and hair: medium from 25, high from 45.
  - **Season:** deep is Dark Autumn or Dark Winter; high contrast is Bright Spring, Bright Winter (light) or True Winter; light is Light Spring or Light Summer; low contrast or a neutral undertone is Soft Autumn or Soft Summer; the rest is True Spring (mean L* from 58), True Autumn or True Summer.
  - **Palettes:** 12 colours that suit, 6 neutrals and 4 to go easy on for each season.
  - **Unclear photos:** a face-quality report that isn't all good still gives a reading, shown as a starting point.
- **Photos:**
  - JPEG or PNG, at most 10 MB and 4096 px. Another format is converted to PNG with a note, and a larger photo is scaled down.
  - Body photos need at least 512 × 384, face photos at least 320 px a side.
  - The picker scales to 2048 px at JPEG quality 90.
  - There is no face or body detection.
- **YouCam costs:** 2 units per try-on pass and 20 per face analysis, once per person unless they redo it; failed tasks are free. A new person's first day costs about 30 units (two outfits and the face analysis), then 4 to 6 a day.

## Architecture

### Layers

Feature-first Clean Architecture. Each feature in `lib/features/<name>/` has:

- `domain`: pure Dart entities, repository interfaces, use cases and services. No Flutter, Firebase, Hive or SQLite imports.
- `data`: data sources (Firebase, Hive, SQLite, dio, assets, files) and repository implementations. Data sources throw; repositories translate exceptions into `Either<Failure, T>` (dartz).
- `presentation`: BLoCs (`flutter_bloc`, with `bloc_concurrency` transformers) and screens. Screens show failures as localized messages.
- `di/init.dart`: registers the feature in GetIt. Widgets receive their BLoC and never resolve repositories.

A service that isn't available yet, such as YouCam in a build without a key, gets an honest stand-in that says so rather than faking success.

### Project layout

```text
lib/
  main_development.dart    # Development entry point: the bundled YouCam key
  main_production.dart     # Production entry point: no YouCam key
  main_init.dart           # Flavor check → Firebase → App Check → Hive + SQLite → DI → language
  app/
    bootstrap.dart         # Runs MainInit, then the app or the startup-failure screen
    in_vogue_app.dart      # MaterialApp.router with the Paper theme
    router/                # go_router: setup resume, tab shell, screens
    widget_refresh.dart    # The widget's background refresh entry point
  core/
    config/                # Environments, App Check, the development key
    data/                  # Error logging; the YouCam client (dio)
    domain/                # Languages, texts, failures, use-case base
    persistence/           # Hive key-value store, SQLite cache, install id, photo fingerprints
    di/                    # Core resources and their disposal
    presentation/          # Design system: tokens, theme, foundations, components
    network/, ui/, utils/  # Exceptions, the startup-failure screen, context helpers
  features/
    setup/                 # The saved setup step and the six setup screens
    location/              # Approximate location and the city
    weather/               # Open-Meteo forecasts and day rules
    photos/                # The system photo picker and the private photo store
    catalog/               # The bundled collection and the person's picks
    colours/               # The skin-tone analysis, colour seasons and the Mirror tab
    wardrobe/              # The outfits the person owns: adding, showing and removing
    auth/                  # Sign in with Apple and Google, Firebase Auth
    account/               # Saving, restoring and deleting the account
    outfits/               # Choosing, claiming and trying on each day's outfit
    home/                  # The Home tab and Shop
    profile/               # The person's name
    home_widget/           # Both widgets: content, pictures, taps, the morning refresh
    preferences/           # Language and default day
    settings/              # The Settings tab
  l10n/arb/                # English, Spanish and Simplified Chinese strings
android/app/src/main/kotlin/com/invogue/app/InVogueWidgetProvider.kt   # The Android widget
ios/In Vogue Widget/       # The iPhone widget extension (SwiftUI)
assets/                    # catalog/, outfits/, fonts/, images/, development/ (git-ignored key)
scripts/                   # Exports, glyphs, icons, Firebase configuration, the rules check
```

### Startup

`bootstrap` runs `MainInit.init`, which checks that the flavor and the Firebase project match (a mismatch stops startup before anything is opened). It then starts Firebase and App Check, opens Hive and SQLite for the flavor, registers the core and the 14 features in GetIt, and reads the saved language and setup step, all before the first frame.

### Navigation

go_router 18. A redirect sends the person to setup or to the tabs. Setup routes nest, so the app reopens on the saved step with the earlier screens beneath it for Back. The tabs live in an indexed stack, with `HomeBloc` and the widget's sync above them. Every route gives an explicit `flutter/material` page so the theme styles it.

### Errors and logging

Repositories log each infrastructure failure through `LogMessages` before turning it into a `Failure`, and uncaught framework and platform errors go the same way. `LogMessagesImpl` writes to the debug console in debug builds and files a report in the Firestore `errors` collection from every build (owner, October 18), so testers' errors reach the team.

- **What a report holds:** the account, when, where (class and method), the error's kind and code (a failed YouCam task's code, a network failure's kind, a Firebase error's plugin and code), a trimmed stack, and the flavor, platform, app version, build and install id. It never holds the exception's message, which may carry personal data.
- **When it's sent:** for the person signed in. Reports made before sign-in wait in memory for it.
- **How many:** each distinct error is filed once a run, at most 50 in all. A report that fails is dropped without reporting itself.
- **The background widget refresh** still logs to the console only.

Read the reports in the Firebase console under Firestore, `errors`.

### Localization

English is the default whatever the phone's language. The person's choice is restored before the first frame, and rapid changes are serialized. Strings come from `lib/l10n/arb/` through `context.translated.<key>`. The knowledge base's texts ship in the bundled data in all three languages, and screens pick theirs with `context.language`.

### Design system

`lib/core/presentation/` implements `../design-spec/` (Swiss Style on white, with Rouge and Rose): tokens, `InVogueTheme.paper` (the only theme; text scaling capped at 200%), foundations (icons, `Pressable`, photos, layout) and the spec's components grouped by area. The fonts are Sofia Sans and Sofia Sans Extra Condensed (variable, SIL OFL). Interface icons come from `phosphoricons_flutter`. The weather glyphs are drawn from the spec's Phosphor path data so rain and snow can animate. Launcher icons are generated from `../design-spec/assets/logo/`.

**Loading** (owner, October 18; this overrides the spec's still Rose placeholders). Every wait shows `RunningRule`: a 2-point bar, a third of the rule's width, runs from start to end every 1.2 s with the curtain easing. With reduced motion, the bar fills the width and fades in and out.

| Where it waits | What runs |
| --- | --- |
| Buttons and sign-in buttons (`busy`) | Along the bottom, in the label's colour. The button keeps its fill and ignores taps. Sign-in turns the other provider off and keeps running through the account's restore and save. |
| Text links and Settings rows (`busy`) | In place of the underline. For Log out and Delete account, a Rouge rule under the title. |
| Content still loading (`RunningRule.content`) | Over a hairline where the content will appear: Picks' weather and pieces, the Outfits tab, Shop, Your picks, and Mirror while it reads the colours. |
| The outfit | `PhotoStage.looking`: along the bottom of the faded photo while the outfit is looked up. While it's being made, inside "Getting your outfit ready…". |
| Catalogue photos (`PhotoSlot.showLoading`) | Along the bottom of the Rose slot until the photo's first frame. |

Busy controls tell screen readers "Loading". Only the thing being waited on moves.

### Native code

- **Android widget:** `InVogueWidgetProvider` (Kotlin, `HomeWidgetProvider`) draws RemoteViews layouts in `res/layout/in_vogue_widget_*.xml` with the fonts in `res/font/` and vector glyphs in `res/drawable/`. The manifest registers it with home_widget's scheduled-update receiver.
- **iPhone widget:** the `In Vogue WidgetExtension` target, iOS 17.0 (the app needs 15.0). Its source is in `ios/In Vogue Widget/`, a folder the target syncs with, so new files join it without a project change. It reads the content from the App Group `group.com.invogue.app.dev`.
- **iPhone background refresh:** `AppDelegate` registers `in_vogue_widget_refresh` with workmanager at launch, and `Info.plist` permits it.
- **Flavors:** each has its own Gradle product flavor and its own iOS Debug, Profile and Release configurations (see [Getting started](#getting-started)).

## APIs and services

### YouCam (Perfect Corp)

Base URL `https://yce-api-01.makeupar.com`, with the API key as a bearer token. The app calls YouCam itself, only after sign-in. Development builds bundle the key; production builds carry none, make no outfits and read no colours.

| Call | Used for |
| --- | --- |
| `POST /s2s/v2.0/file`, then `PUT` to the upload URL it returns | Uploads the body photo, or a face picture, and gets a file id |
| `POST /s2s/v2.0/task/cloth-v4` | AI Clothes try-on: `src_file_id` (the photo) or `src_file_url` (the last pass's picture), `ref_file_url` (the garment photo) and `garment_category` |
| `POST /s2s/v2.0/task/skin-tone-analysis` | Facial colour tones of the face photo (skin, brows, lips, hair, eyes), at `face_angle_strictness_level: low` |
| `GET /s2s/v2.0/task/{tool}/{task_id}` | Polls a task: every 5 seconds for try-on (up to 4 minutes), every 3 for the skin-tone analysis (up to 2) |
| The result's URL (no key) | Downloads the finished picture; YouCam keeps it about 2 hours |
| `POST /s2s/v2.0/task/delete` | Discards a task once its picture is kept |

When YouCam refuses a garment's photo (`error_invalid_ref`), that piece is never chosen again and the day switches to another outfit. When the units run out, outfits and colour readings stop for everyone with "No more outfits can be made for now."

### Firebase

| Service | Used for |
| --- | --- |
| Authentication | Sign in with Apple (iPhone only) and Google |
| Cloud Firestore | The account and everything under `users/{uid}` (see [Data](#data)); offline persistence gives the phone a copy |
| Cloud Storage | Photos and outfit pictures under `users/{uid}/` |
| App Check | On, with debug tokens in debug builds, Play Integrity on Android and App Attest on iPhone, but never enforced (owner decision), so it changes nothing |

Projects: `in-vogue-dev` (development) and `in-vogue` (production).

### Open-Meteo

`GET https://api.open-meteo.com/v1/forecast`, with no key: `latitude`, `longitude`, `timezone=auto`, `forecast_days=3`, and the hourly `temperature_2m`, `apparent_temperature`, `precipitation_probability`, `precipitation`, `snowfall`, `weather_code` and `wind_gusts_10m`. Called from the app and from the widget's morning refresh.

### On the phone

| Package | Used for |
| --- | --- |
| `geolocator`, `geocoding` | Approximate location and the city's name |
| `image_picker` | The body and face photos, from Photos or Gallery |
| `sign_in_with_apple`, `google_sign_in` | Sign-in, handed to Firebase Auth |
| `url_launcher` | "Buy at Everlane" |
| `home_widget` | The widgets' shared content, redraws, scheduled updates (Android) and taps |
| `workmanager` | The morning refresh |
| `path_provider_foundation` | The App Group's container on iPhone |

### Offline: the catalog

Today's app reads a bundled catalog. On the Mac, `../resources/` pulls Everlane's women's collection from Shopify's Global Catalog and builds the knowledge base (weather, occasions, styling and outfits) with Python. `scripts/export_*.py` copies what the app needs into `assets/`, so a change ships with an app release.

The next recommender reads a curated catalog from Firebase instead (owner, October 19). Claude labelled every piece and colour and put together 500 outfits in `../resources/catalog/curation/`; `../resources/tools/catalog/build_outfit_catalog.py` checks and builds them, and `upload_outfit_catalog.py` puts them on `in-vogue-dev` with the development admin key. It is live there; the app doesn't read it yet. The design is [docs/recommender-design.md](docs/recommender-design.md).

## Data

### Firestore

| Path | Holds |
| --- | --- |
| `users/{uid}` | The profile: name, location, photos (body, face), plan, `createdAt`, `updatedAt` |
| `users/{uid}/wishlist/{colourwayId}` | The person's picks |
| `users/{uid}/days/{yyyy-mm-dd}_{occasion}` | Each day's outfit: cell, outfit, `status`, the phone making it, progress, `picturePath`, `problem` |
| `users/{uid}/suggestions/{signature}` | When each outfit was suggested, and any piece whose photo YouCam refused |
| `users/{uid}/tryOns/{photo}-{signature}` | The picture made of an outfit on a photo: the photo's fingerprint, the signature and the picture's path |
| `users/{uid}/colorProfiles/{sha256}` | The colours analysed from a face photo: skin, brows, lips, hair, eyes, whether the photo was clear, and `analysedAt`. The one analysed last is the person's reading |
| `users/{uid}/wardrobe/{id}` | An outfit the person owns: `name`, `colours` (one or more; an outfit saved before October 18's change holds one `colour`, still read), `bands` (feels-like bands), `rain`, `occasions`, `photo` (`path` in Storage, `url`) and `createdAt` |
| `errors/{id}` | An error report: account, time, where, the error's kind and code, stack, flavor, platform, version, build and install id. The app may only add its own; nobody reads or changes one from the app |
| `outfits/{id}` | A curated outfit (not read by the app yet): name, picture, pieces with links and try-on passes, weathers, colour seasons, occasions, `fits` (season × weather keys), taste and protection fields, `order` and `sample`. Anyone reads the 40 with `sample == true`; a signed-in person reads all; only the admin key writes |
| `catalog/outfits` | The catalog's version, size and onboarding sample; anyone reads it |

In the names above, `{photo}` is the first 16 characters of the photo's SHA-256.

### Storage

| Path | Holds |
| --- | --- |
| `users/{uid}/photos/<file>` | The body and face photos |
| `users/{uid}/days/{date}_{occasion}.jpg` or `.png` | A finished outfit picture; later days with the same photo and outfit share it |
| `users/{uid}/wardrobe/{id}.jpg` or `.png` | The photo of an outfit the person owns |
| `catalog/v2/sample/{id}-{fingerprint}.jpg` | A sample outfit's picture; anyone reads it |
| `catalog/v2/outfits/{id}-{fingerprint}.jpg` | Every other outfit's picture; a signed-in person reads it |

### On the phone

Everything sits in `<support>/in_vogue/<flavor>/`:

- **Hive** (`preferences_<flavor>`): the language, default day, setup step, location, picks and those last saved on the account, the name, the photo records, the install id, the unfinished try-on jobs and the colour readings under way.
- **SQLite** (`cache.sqlite`): forecasts, with expiry.
- **Files:** `photos/`, `outfits/{uid}/` (with `made/`), `wardrobe/{uid}/` and `downloads/`.
- **The widgets:** Android stores their content in home_widget's preferences. iPhone stores it in the App Group: its `UserDefaults` and a `widget/` folder of pictures.

### Bundled assets

`assets/catalog/everlane_women.json` (the collection), `assets/outfits/outfits.json` (1,749 outfits in 96 cells), the fonts and images.

## Getting started

### Toolchain

Flutter 3.44.4 and Dart 3.12.2, Xcode 26.3, CocoaPods 1.16.2, Java 17 (Java 21 for the Firestore emulator), the Firebase and FlutterFire CLIs. iOS 15.0 or later; Android minSdk 24. On the owner's Mac, Flutter runs through the `flutterN` alias in an interactive zsh: `zsh -ic 'flutterN …'`.

### Flavors and identity

| Flavor | App ID | Firebase project | Launcher name | Entry point |
| --- | --- | --- | --- | --- |
| development | `com.invogue.app.dev` | `in-vogue-dev` | In Vogue Dev | `lib/main_development.dart` |
| production | `com.invogue.app` | `in-vogue` | In Vogue | `lib/main_production.dart` |

Plain `flutterN run` uses development. The iPhone widget's bundle IDs add `.In-Vogue-Widget`. The Apple team is `Q56R6X96PZ`. Development release builds on Android are signed with the debug key; production stays unsigned until `android/key.properties` exists (see `android/key.properties.example`).

### A new checkout

1. **Packages and strings:**
   ```sh
   flutterN pub get
   flutterN gen-l10n
   ```
2. **Native Firebase files.** The Dart configuration is committed; `google-services.json` and `GoogleService-Info.plist` are git-ignored. This needs `firebase login`, the FlutterFire CLI and the `xcodeproj` Ruby gem (which comes with CocoaPods):
   ```sh
   scripts/configure_firebase.sh development
   scripts/configure_firebase.sh production
   ```
3. **The development YouCam key.** This writes the git-ignored `assets/development/youcam_api_key.txt` from `secrets/youcam_api.txt`; rebuild afterwards:
   ```sh
   python3 scripts/write_development_key.py
   ```

### Running

```sh
flutterN run --flavor development -t lib/main_development.dart
flutterN run --flavor production -t lib/main_production.dart
```

The VS Code launch configurations do the same.

- **New native plugins:** stop the app and run it again; a hot restart doesn't load them.
- **iOS:** plugins come through CocoaPods, so open `ios/Runner.xcworkspace`, not the project. To run from Xcode, first write the flavor's configuration:
  ```sh
  flutterN build ios --config-only --debug --flavor development -t lib/main_development.dart
  ```
- **The project file:** `pod install` may rewrite `ios/Runner.xcodeproj/project.pbxproj` in an older format. Keep the version Xcode saved.

### Release builds

`scripts/build_release.sh` makes a flavor's release builds in four steps, stopping at the first that fails:

1. Builds the iOS archive (`flutter build ipa`).
2. Builds the Android APK (`flutter build apk`).
3. Moves the archive and the APK into `release/`. An IPA, when `flutter build ipa` exports one, isn't kept.
4. Deletes `build/` to save space.

When a step fails, `build/` stays as it was, for a look.

```sh
scripts/build_release.sh              # development
scripts/build_release.sh production   # production, once its signing is set up
```

- **Where the builds go:** `release/in-vogue-<flavor>-<version>-<date-time>/`, holding `in-vogue-<flavor>-<version>.xcarchive` and `.apk`. `release/` is git-ignored.
- **Need an IPA?** Open the `.xcarchive` and export one from Xcode's Organizer.
- **Signing:** the archive needs Xcode signed in to team `Q56R6X96PZ`. Development APKs are signed with the debug key.
- **Time:** it takes several minutes, and the next build starts from scratch.
- **Option:** `FLUTTER` overrides the Flutter command (by default, what `flutterN` points to).

### Sign-in prerequisites

- **Firebase Auth:** the Apple and Google providers turned on in each project.
- **Android:** each signing key's SHA-1 on the flavor's Android app, then the native files refreshed.
- **iPhone:** the Sign in with Apple capability, and a URL type with each flavor's `REVERSED_CLIENT_ID`.

## Commands

Run from `in-vogue/`; on the owner's Mac, wrap Flutter and Dart commands in `zsh -ic '…'`.

| Task | Command |
| --- | --- |
| Packages | `flutterN pub get` |
| Translations (after editing `.arb` files) | `flutterN gen-l10n` |
| Mockito mocks | `dart run build_runner build --delete-conflicting-outputs` |
| Format | `dart format lib test integration_test` |
| Analyze | `flutterN analyze` |
| Test | `flutterN test` |
| Type-check the iPhone widget (no build) | `xcrun swiftc -typecheck -parse-as-library -sdk "$(xcrun --sdk iphoneos --show-sdk-path)" -target arm64-apple-ios17.0 "ios/In Vogue Widget/"*.swift` |
| Export the bundled data, in this order | `python3 scripts/export_catalog.py`, then `python3 scripts/export_outfits.py` (it stops if `../resources/kb/translations.v1.json` lacks a text) |
| Widget glyphs for both platforms | `python3 scripts/generate_widget_glyphs.py` |
| Launcher icons | `scripts/generate_app_icons.sh` |
| Native Firebase files | `scripts/configure_firebase.sh development` (or `production`) |
| The development YouCam key | `python3 scripts/write_development_key.py` |
| Check the Firestore rules on the emulator (Java 21) | `JAVA_HOME=<java 21> firebase emulators:exec --only firestore --project demo-in-vogue "python3 scripts/check_firestore_rules.py"` |
| Check the Storage rules on the emulator (Java 21) | `JAVA_HOME=<java 21> firebase emulators:exec --only storage --project demo-in-vogue "python3 scripts/check_storage_rules.py"` |
| Build the curated outfit catalog (from `../resources`) | `python3 tools/catalog/build_outfit_catalog.py` |
| Upload it to development (from `../resources`; a dry run without `--apply`; needs `firebase-admin`) | `python3 tools/catalog/upload_outfit_catalog.py --key ../in-vogue/secrets/<service-account>.json --apply --prune` |
| Deploy the rules to development | `GOOGLE_APPLICATION_CREDENTIALS=secrets/<service-account>.json firebase deploy --only firestore:rules,storage --project in-vogue-dev --non-interactive` |
| Release builds: the iOS archive and APK into `release/`, then `build/` deleted | `scripts/build_release.sh [development\|production]` |
| The device startup test (a simulator or phone) | `flutterN test integration_test/startup_test.dart --flavor development -d <device-id>` |

## Testing

`flutterN test` runs 880 tests in about a minute, with no native build. They cover:

- **The foundation:** the flavor and Firebase isolation, the iOS flavor wiring, language restore and fallback, real Hive and SQLite behaviour, complete translation files, and 320-point screens at 200% text.
- **The design system:** every token, glyph path and component, checked against `../design-spec/` when it sits beside the repository.
- **The app:** routes and resuming setup; every screen; the location, forecast and day rules; the photo rules; the bundled data (every text in three languages); choosing and claiming days across phones; making outfits and reading colours against scripted YouCam fakes, including their caches; the colour seasons; saving, restoring and deleting the account; the rules' plan lock; and both widgets' content, taps and refresh.
- **The native widgets:** checked in place of a build by `test/core/android_widget_configuration_test.dart` and `ios_widget_configuration_test.dart`.

Each package is tested the way its own docs say: platform-interface mocks for plugins, `withClock` for time, bloc_test's `MockBloc` for screens, `fake_cloud_firestore`, sqflite_common_ffi and http_mock_adapter. Tests never call YouCam or real Firebase. The device test in `integration_test/` starts the real native Firebase, Hive and SQLite.

All checks run locally; the project has no CI by the owner's choice.

## Security and privacy

- **Rules:** `firestore.rules` and `storage.rules` let each person reach only `users/{uid}/**`. Uploads must be images under 10 MB. Nobody can change their own plan.
  - `errors`: a signed-in person may add their own report, with fixed fields and sizes, and nothing more.
  - The outfit catalog: anyone may read the onboarding sample (`outfits` with `sample == true`, `catalog/outfits`, the `catalog/v2/sample/` pictures); a signed-in person reads every outfit and picture; only the admin key writes.
  - `scripts/check_firestore_rules.py` and `scripts/check_storage_rules.py` keep the rules in step with the app on the emulators.
- **Keys:** `secrets/` (the YouCam key and the development admin key), the bundled development key and the native Firebase files are git-ignored.
  - A key inside an app can be extracted, so production carries none yet.
  - A YouCam proxy function, holding the key on a server behind App Check, is to be reconsidered before release.
- **Photos and pictures:** they go to YouCam (to make outfits and read colours) and to Firebase.
  - Log out removes this account's outfit pictures and colour readings under way from the phone.
  - Delete account removes everything from Firebase and the phone.
- **Error reports:** they carry the account id and never the exception's message. They stay after Delete account, since the app can't delete them.

## Roadmap

### Checked on a phone

- **Sign-in (October 16):** Google sign-in works, and an Apple sign-in saved the profile, both photos and four favourites to Firebase.
- **Owner's device test (October 18):** the development build with the bundled YouCam key, the occasion fix and the Settings changes all passed.
- **Still to check:** a real end-to-end YouCam run, the October 17 work (two-day outfits, photo rules, returning users), Mirror's colour reading, and both widgets.

### Next

From the owner's device test, October 18, in this order:

1. **Animated loading everywhere.** Done October 18 with the running rule (see [Design system](#design-system)).
2. **The widget's temperature on narrow widgets.** Done October 18, waiting for the owner's build: the numeral fits any width on Android and iPhone.
3. **Makeup doesn't work on the owner's phone.** Fixed October 18; the owner's YouCam run confirms it. The skin analysis refused the face photo's angle at `high` strictness and had never succeeded. The app didn't know the angle codes, so it said "Your photo is fine." The analysis now runs at `low`, every photo error says what to change, failed tasks are logged with YouCam's code, and a success without `face_quality` keeps the person's colours. The error the owner saw:

   ```json
   {"status": 200, "data": {"error": "error_face_angle_rightward",
     "error_message": "The face is turned too far to the right for accurate analysis. Slightly turn head to the left and try again.",
     "results": null, "task_status": "error"}}
   ```
4. **Replace Makeup with a colour palette and My Wardrobe.** Done October 18 as the Mirror tab (see [Reading colours](#reading-colours)); user testing is the owner's. Makeup is gone: its looks, recipes, steps and pictures. The face photo and the skin analysis stay. The owner's design: the season and why, then the palette in round swatches, then My Wardrobe; no face photo on the page, since it belongs in Settings; without one, Mirror asks for a selfie.
5. **My Wardrobe.** Done October 18 on Mirror: adding an outfit the person owns (photo, name, colours, weather, occasions), the grid, the details and Remove. Home's recommendations from the wardrobe, one for today and one for tomorrow, go at the bottom of the Today and Tomorrow tabs (owner, October 19).
6. **Mirror and Settings after the owner's check.** Done October 18: a palette colour opens its name and how to wear it, "See your full analysis" opens the whole skin analysis as a sheet, an outfit takes several colours, and Settings' profile square shows the face photo or the initial, never bare Rose. Error reports now carry YouCam's codes, and widget publishes run one at a time.

### Open work

- **Recommender v2 (owner, October 19).** The curated catalog of 500 outfits is on `in-vogue-dev` with its pictures and rules. Next: the app reads it (onboarding sample, the catalog on Home with favourites), then the recommender, the learning and the wardrobe, as [docs/recommender-design.md](docs/recommender-design.md#13-delivery-plan) plans.
- **Check both widgets on phones (owner).**
  - Android: Large, Medium and Small; the switch at 06:00, 09:00 and midnight; a tap opening Home on that day; the waiting and stale states; the morning refresh (about 05:30, network on).
  - iPhone: the same, with Background App Refresh on, since iOS picks when the refresh runs.
- **Membership rules for the MVP (owner decision).**
  - The plan so far: Free gives 14 outfits over the account's whole life, and one outfit a day (its 3 makeup looks went with makeup on October 18). Pro is shown at $7.99 a month or $59.99 a year, and Go Pro joins a waiting list, with no payments.
  - Every new account is created Pro today, so each tester's YouCam spend is uncapped.
  - The decision unblocks three pieces of work:
    - **Free-plan limits:** count outfits shown, and lock the counters in the rules so the app can only raise them. Without a server they can't be fully tamper-proof.
    - **The Go Pro screen:** "In Vogue Pro", three benefits, the price and the waiting list. The design-system pieces exist.
    - **Free-plan locks:** the plan line on Home, Go Pro in Settings, and browsing limited to about 30 current-season pieces.
- **How testers get the app (owner decision).**
  - Firebase App Distribution is quickest. On Android it takes the debug-signed development build as is.
  - On iPhone it needs each tester's device registered, or TestFlight with an App Store Connect record for `com.invogue.app.dev`.
- **"Other outfits" on Home (owner decision):** Pro gets up to 3 more outfits a day. Each is a full try-on, 4–6 units.
- **Holiday and evening occasions (owner input).**
  - Public holidays should count as casual days, which needs a dated holiday list for each country.
  - Still open: whether evenings default to Staying in (Monday to Thursday) and Going out (Friday to Sunday).
- **Review the copy (owner).** Every word in the app, in all three languages.
- **A landing page (owner):** the terms, a privacy policy, issue reporting, SEO and a wishlist. Once it exists, the app links its terms, privacy policy and issue reporting (in Settings), and the stores get its privacy policy.
- **Old pictures and records (owner decision on how long to keep them).**
  - Only Delete account removes them today. A Storage lifecycle rule and Firestore TTL policies could clean up without a server.
  - Never expire `suggestions`.
  - Days can share a picture now, so a clean-up must also remove the `tryOns` entry of every picture it deletes.
- **Keep the catalog fresh.**
  - The catalog is a snapshot from October 14. Re-run the pull and the exports regularly, and mark pieces no longer for sale instead of linking to a dead page.
  - A rebuild reshuffles about 40% of outfits, so it needs the owner's OK.
- **The skill evals** in fresh sessions, with and without each skill.
- **Push to `origin`** (owner's go-ahead).

### Production checklist

The production flavor (`com.invogue.app`, Firebase `in-vogue`) needs these before release:

- [ ] Check that the Firestore `(default)` database and Storage exist in `in-vogue` (Storage needs the Blaze plan).
- [ ] Deploy `firestore.rules` and `storage.rules` to `in-vogue` (owner; the development admin key can't).
- [ ] Turn on the Apple and Google providers in Firebase Auth for `in-vogue`.
- [ ] Create the Android release key and `android/key.properties`, add its SHA-1 and SHA-256 to the `in-vogue` Android app, then refresh the native files with `scripts/configure_firebase.sh production`.
- [ ] iOS: Sign in with Apple for `com.invogue.app` (team `Q56R6X96PZ`), distribution signing and an App Store Connect record.
- [ ] Decide how production gets the YouCam key, and reconsider a YouCam proxy function: one callable function holding the key in Secret Manager, answering signed-in people with App Check and applying per-person limits.
- [ ] Keep the YouCam account funded.
- [ ] The store requirements: the privacy policy (from the landing page), the App Store privacy details and Google Play's data-safety form.
- [ ] The iPhone widget for production:
  - production entitlements for Runner and the extension with `group.com.invogue.app` (owner, in Xcode);
  - `HomeWidgetDataSourceImpl.appGroupOf(production)` (AI);
  - the extension's version and build number set to match the app's.
- [ ] Build the production flavor and check sign-in, the first outfit, Mirror's colours and Delete account on a device.
- [ ] Sign the release builds, upload them to the chosen channel, merge, push and tag.

### Decision log

Each line is an owner decision, kept so that old ideas stay dead.

- **October 14:** Everlane's women's collection became the first catalog. Outfits are tried on piece by piece, with Everlane's whole-outfit photos held in reserve.
- **October 15:** the design became Swiss Style on white with Rouge and Rose, and the logo was finalised. The icons moved to `phosphoricons_flutter`.
- **October 16:** setup became photo before sign-in, with no guest outfit. No photo checks ("just trust the user"). No native builds unless asked, never test packages, and no screen reuse.
- **October 17:** no units cap ever, everything in the app, the newest package versions without asking, and makeup starts by itself (makeup was replaced on October 18).
- **October 18, morning:** Saturday and Sunday default to Casual. Development builds bundle the YouCam key, and a YouCam function is to be reconsidered before release. The app updates the widget, plus a morning refresh.
- **October 18, later:** the catalog stays bundled, and App Check stays in the app, never enforced. The focus became an MVP for testers on the development flavor.
- **October 18, last:** each photo and outfit is tried on once, and looks are kept per face photo. Error reports go to a Firestore `errors` collection.
- **October 18, after the device test:**
  - Loading must visibly move, overriding the spec's still placeholders. Of three options, the owner picked the running rule.
  - The skin analysis runs once per person; replacing the face photo keeps the colours unless the person redoes it from Settings.
  - Makeup gives way to a skin-tone colour palette and My Wardrobe on one page: the Mirror tab (Home, Mirror, Settings). It shows the season and why and the palette in round swatches, never the face photo, which belongs in Settings. Setup asks for the selfie for the skin tone and colour analysis, never for makeup.
  - Wardrobe uploads, dropped before, are planned, and the person's own outfits weigh more.
  - My Wardrobe: a person adds photos of outfits they own with a name, colours, weather and occasions; Mirror shows them in a grid with their details. Home recommending from them waits for the owner.
  - After the owner's check: a palette colour opens its name and how to wear it, the full skin analysis opens as a sheet, and an outfit takes one or more colours.
- **October 19:** the recommender is rebuilt on a catalog Claude curates outside the app and stores in Firestore, reversing "the catalog stays bundled". The app only filters by colour season and weather and ranks; it never decides what suits a piece.
  - A catalog item is an outfit of up to 4 shop pieces, each buyable and tried on piece by piece; about 500, with plain names; the picture is the main piece's model photo in Firebase Storage, and the other pieces copy what the model wears when the shop sells them.
  - Skin colours are the 12 colour seasons. Garment categories stay hidden.
  - Weathers: Hot ≥ 26 · Warm 20–26 · Mild 14–20 · Cool 8–14 · Cold 0–8 · Freezing < 0 °C feels-like; a piece lists every weather it can be worn in, layered if needed. Skirts, dresses and shorts are bare legs only.
  - Occasions, ticked: Work, Casual, Going out, Event, Staying in, Active.
  - Onboarding shows a fixed sample of 30–50 outfits readable without sign-in; picks are optional, go to the wishlist and weigh similar outfits without forcing them. After sign-in, Home shows the whole catalog, paged, with favourites, nothing weather-based.
- **October 19, later:**
  - Setup's picks step keeps the weather at the top; only the grid below changes, to the same 40 sample outfits for everyone, because picks record general taste. Home's Outfits tab keeps its weather chips as filters (Hot, Warm, Mild, Cool, Cold, Freezing, Rain) and opens on all outfits. Tapping an outfit opens the Shop screen. The person's own outfit for the day goes at the bottom of the Today and Tomorrow tabs.
  - The app's occasions stay Work, Casual, Going out and Staying in; Event and Active stay in the catalog's data and aren't implemented. An unclear skin analysis is ignored, like a missing one.
  - Nothing is migrated: the old system's records in `in-vogue-dev` are deleted (single-piece wishlist entries, days, suggestions, try-ons and their pictures). Log out clears only the phone's copy of the taste model; Delete account deletes it from the account.
  - The 50 cold-day outfits with a coat added stay. An outfit's colour seasons come from its top or dress, and from its skirt or trousers when they aren't neutral; the coat doesn't count. The catalog stays at 500 outfits.
