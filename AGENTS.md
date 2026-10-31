# AGENTS.md

In Vogue is a Flutter weather app for Android and iPhone. Each day it shows the person, head to toe, in a real outfit from a partner catalog (Everlane today) picked for the day's weather and occasion, with the clothing colours that suit them, read from a selfie, a link to buy each piece and a home-screen widget. For now it is for women aged 16 and older (owner, October 26, 2026).

- **Read [README.md](README.md)** for the overview, stack, setup, commands and troubleshooting. The architecture, data model, APIs and other area details are in the skills (below).
- **Focus now (owner, October 18):** an MVP for testers on the development flavor (`com.invogue.app.dev`, Firebase `in-vogue-dev`). Production waits.
- **Stack:** Flutter 3.44.4, Dart 3.12.2, BLoC, GetIt, dartz, Equatable, Firebase (Auth, Firestore, Storage), Hive, SQLite, YouCam, Open-Meteo, `home_widget` and `workmanager`, a Kotlin Android widget and a SwiftUI iPhone widget.
- **Workspace** (`weather-dot-me/`, not a git repo): `in-vogue/` is this app and the only repository. `design-spec/` is the design specification (read-only). `resources/` holds the catalog, the knowledge base and their Python tools. `app certs and profiles/` is the owner's.

## Commands

Run from `in-vogue/` through an interactive zsh, because `flutterN` is a shell alias. Never use `flutter`.

| Task | Command |
| --- | --- |
| Packages | `zsh -ic 'flutterN pub get'` |
| Translations, after editing `.arb` files | `zsh -ic 'flutterN gen-l10n'` |
| Mocks, after changing `@GenerateMocks` or a mocked interface | `zsh -ic 'dart run build_runner build --delete-conflicting-outputs'` |
| Format | `zsh -ic 'dart format lib test integration_test'` |
| Analyze | `zsh -ic 'flutterN analyze'` |
| Test (about a minute) | `zsh -ic 'flutterN test'`; one file: `zsh -ic 'flutterN test test/features/outfits/make_outfit_test.dart'` |
| Type-check the iPhone widget (no build) | `xcrun swiftc -typecheck -parse-as-library -sdk "$(xcrun --sdk iphoneos --show-sdk-path)" -target arm64-apple-ios17.0 "ios/In Vogue Widget/"*.swift` |

Other commands, run from `in-vogue/` unless noted:

| Task | Command |
| --- | --- |
| Export the bundled collection | `python3 scripts/export_catalog.py` |
| The recommender's test fixtures | `python3 scripts/export_catalog_fixture.py` after a catalog rebuild; `python3 scripts/fetch_weather_year.py` for the year of weather |
| Widget glyphs for both platforms | `python3 scripts/generate_widget_glyphs.py` |
| Launcher icons | `scripts/generate_app_icons.sh` |
| Native Firebase files | `scripts/configure_firebase.sh development` (or `production`) |
| The development YouCam key | `python3 scripts/write_development_key.py` |
| Check the Firestore rules on the emulator (Java 21) | `JAVA_HOME=<java 21> firebase emulators:exec --only firestore --project demo-in-vogue "python3 scripts/check_firestore_rules.py"` |
| Check the Storage rules on the emulator (Java 21) | `JAVA_HOME=<java 21> firebase emulators:exec --only storage --project demo-in-vogue "python3 scripts/check_storage_rules.py"` |
| Build the curated catalog (from `../resources`, outside this repo) | `python3 tools/catalog/build_outfit_catalog.py` |
| Upload it to development (from `../resources`; a dry run without `--apply`; needs `firebase-admin`) | `python3 tools/catalog/upload_outfit_catalog.py --key ../in-vogue/secrets/<service-account>.json --apply --prune` |
| Deploy the rules to development | `GOOGLE_APPLICATION_CREDENTIALS=secrets/<service-account>.json firebase deploy --only firestore:rules,storage --project in-vogue-dev --non-interactive` |
| Release builds into `release/` | `scripts/build_release.sh [development\|production]` |
| The device startup test | `zsh -ic 'flutterN test integration_test/startup_test.dart --flavor development -d <device-id>'` |

A task is done only when analyze says "No issues found!" and every test passes.

## Boundaries

**Always**
- Think it through against the product rules, the costs and how it could be abused before you build ("think logically about what you are doing", the owner's words).
- Follow the owner's latest decision over older notes, the design spec, your memory and your own ideas.
- Say what you're about to do before long steps. Report real results: exact test counts, real failures, skipped steps.
- Give a service that isn't ready an honest stand-in that says so, never a fake success.

**Ask first**
- Pushing, merging into `main` or tagging.
- Swapping a package or approach the owner named: offer 2–3 options with a recommendation.
- Decisions that are the owner's: product rules, pricing, membership, what testers see.
- Subagents and long jobs, such as skill evals or a catalog rebuild.

**Never**
- Spend YouCam units yourself. Real YouCam runs are the owner's.
- Run `flutterN build`, `flutterN run`, `scripts/build_release.sh`, simulators or `integration_test/` unless asked. The owner's device runs are the native check.
- Edit Xcode capabilities, entitlements, signing or URL types, or Firebase and Apple console settings. Give the owner exact steps instead.
- Deploy to production (`in-vogue`). The admin key is for `in-vogue-dev` only.
- Print, log or commit a secret (see Security).
- Add an AI co-author (`Co-Authored-By`), GitHub workflows or any CI/CD.
- Undo or scale back finished work.
- Touch `design-spec/`, the owner's signing files, or the reference projects Kostuma and Utano.

## Workflow

1. Branch from `main` for each task: `feat/…`, `fix/…`, `docs/…`.
2. Read only what the task needs. Plan what's wrong today, the design, the tests and the build order.
3. Write the test first, then the code, then run the checks (the `verifying-changes` skill).
4. Review the change, then commit in small groups with scoped subjects, such as `feat(outfits): …`, `fix(account): …`, `test(…)`, `chore(…)` or `docs: …`. The subjects alone should tell the story.
5. Update the docs in the same task: tick Open work, record owner decisions (rules here, how things work in the matching skill; README keeps only the overview, setup, commands and troubleshooting) with the date, and update any skill whose facts changed.

The owner commits too: read before you edit, and never overwrite their work. When CocoaPods rewrites `ios/Runner.xcodeproj/project.pbxproj`, keep the version Xcode saved.

## Code style

- Feature-first Clean Architecture in `lib/features/<name>/`: `domain` (pure Dart), `data` (Firebase, Hive, SQLite, dio, assets), `presentation` (BLoC and screens) and `di/init.dart` (GetIt).
- Repositories return `Either<Failure, T>`. Data sources throw, and repositories translate. Values use Equatable.
- Every string on screen goes through `context.translated.<key>` and into all three of `lib/l10n/arb/app_en.arb` (the default), `app_es.arb` and `app_zh.arb`.
- Build screens from the design system in `lib/core/presentation/` (import `presentation.dart`). Each screen is its own; never reuse a setup screen, share widgets instead.
- Comments are short and say what the code is or does. Never where it's used, and no product stories.
- Packages: always the newest version, never downgrade. Settle version clashes with `dependency_overrides` and a one-line reason.

## Testing

- Test our code, never the packages, and mock each package the way its own docs say. A thin wrapper around an SDK gets no tests.
- Tests never call YouCam or real Firebase: fakes, `fake_cloud_firestore`, Mockito and bloc_test.
- Native code can't be compiled here. Keep `test/core/android_widget_configuration_test.dart` and `ios_widget_configuration_test.dart` in step, type-check Swift, and ask the owner to build.

## Product rules: never break these

- The app is In Vogue. No clothing prices anywhere; the only price is Go Pro's ($7.99 a month or $59.99 a year).
- Photos are chosen from Photos or Gallery, never taken: no camera, and never the words "take a photo". Trust the photo: no checks beyond the size and format rules.
- YouCam: nothing before sign-in, and no units cap, counter or quota, ever. Everything runs in the app, with no servers or Cloud Functions (a YouCam proxy is to be reconsidered before release).
- No partner credits such as "Outfits by {Brand}"; "Buy at {Brand}" is fine. No design decision rests on a partner. Rights to the catalog and brand content are in place, so don't raise licensing.
- One white theme: never dark mode or an appearance setting.
- Clothes only: no shoes, bags or accessories, and people keep their own shoes. Never hair changes.
- Outfits come from the whole collection. Loved outfits add weight; never-suggested outfits come first, then the one suggested longest ago.
- English unless the person picks another language; never follow the phone's.
- Never save or cache an error or failure, anywhere: not in Firestore, on the phone or in memory. Caches keep results only; a failure is shown and the next try asks again (owner, October 20).
- A day whose outfit the catalog no longer has gets another one from the recommender (owner, October 20).

**Not building** (owner decisions): servers, webhooks or schedulers · a units cap or kill switch · a guest outfit · photo detection · the camera · dark mode · partner credits · App Check (never enforced, so removed; owner, October 31) · AI chat, social features, calendar or trip planning, quizzes, skin-health reports, hair changes, in-app checkout or endless feeds. Wardrobe uploads were on this list until October 18; they're now planned (Next, item 5). Loading the catalog from Firebase was on it until October 19: outfits now come from a curated catalog in Firestore (owner, October 19; the design is `../docs/recommender-design.md`, outside the repository).

## Security

- `secrets/` is git-ignored. It holds the YouCam key and secret and the development Firebase admin key. `assets/development/youcam_api_key.txt` is git-ignored too: development builds bundle it, production builds never do. The native Firebase files are git-ignored. Never print, log or commit any of them.
- Firestore and Storage rules give each person only `users/{uid}/**`, and nobody can change their own `plan`. The exceptions: `errors`, where a signed-in person may only add their own report; and the outfit catalog (`outfits`, `catalog`, Storage `catalog/`), which anyone reads for the onboarding sample, a signed-in person reads whole, and only the admin key writes. Check a rules change on the emulator before deploying it to development (`scripts/check_firestore_rules.py`, `scripts/check_storage_rules.py`).

## Open work

*Pending* means nothing blocks it. *Blocked* names who it waits on. The [roadmap](#roadmap) and the production release's [checklist](#production-checklist) close this section.

**Next, in this order** (from the owner's device test, October 18):

1. [x] **Animated loading everywhere.** Done October 18. The owner picked the running rule from three options: a 2-point bar runs along whatever is working, at every wait in the app. This overrides the spec's still Rose placeholders (`design-spec/guide/04-photography.md`, `06-motion.md`). How it works is in the `building-ui` skill.
2. [x] **The widget's temperature on narrow widgets.** Done October 18, and again for Android on October 27 (`fix/widget_numeral_picture`, waiting for the owner's build). The launcher draws a widget's text in the phone's font, not Sofia Sans, so the October 18 sizing still showed "20°" as "2". On Android the numeral is now a picture in its own font that only shrinks to fit the room each size gives it. On iPhone, it shrinks to a quarter of its size before it would wrap.
3. [x] **Makeup doesn't work on the owner's phone.** Fixed October 18; it needs the owner's YouCam run to confirm. The `errors` collection was empty (failed YouCam tasks were never logged), and neither development account had a colour profile, so the skin analysis had never succeeded. It refused the face photo's angle (`error_face_angle_rightward`) at the strict `high` level. Then, because the app didn't know the analyzer's seven angle codes, it said "Your photo is fine."
   - The analysis now runs at `low` strictness, since the app trusts the photo (owner to confirm).
   - Every photo error says what to change (`PhotoAdvice`), for the colour reading and try-on alike.
   - Failed tasks are logged with YouCam's code, so they reach `errors`.
   - A success without a `face_quality` report keeps the person's colours.
4. [x] **Replace Makeup with a colour palette and My Wardrobe.** Done October 18 as the **Mirror** tab (Home, Mirror, Settings); user testing is the owner's. Makeup is gone, code and tests; the face photo and the skin analysis stay (`lib/features/colours`). Owner decisions, October 18:
   - Mirror shows the colour season and why, then the palette in round swatches, then My Wardrobe. No face photo on the page: it belongs in Settings. Without one, Mirror asks for a selfie.
   - Setup and Settings say the face photo is for the skin tone and colour analysis. Never mention makeup.
   - The season is In Vogue's own hardcoded suggestion from YouCam's sampled colours (`SeasonRules`); YouCam gives no season or undertone.
   - The skin analysis runs once per person, and its result is kept. A new face photo doesn't change who they are, so it keeps the colours; Settings offers "Redo skin analysis" when the face photo is replaced, and only that reads them again.
5. [x] **My Wardrobe.** Done October 18, below the season on Mirror (`lib/features/wardrobe`). Owner decisions, October 18:
   - A person adds a photo of an outfit they own, chosen from Photos or Gallery, with its name, its colours (one or more), the weather it suits (feels-like bands and rain) and its occasions.
   - Mirror shows their outfits in a grid; a tile opens the outfit's details, as the catalog's tiles do, with Remove, which asks first.
   - Home recommends from the wardrobe too: one for today and one for tomorrow, at the bottom of the Today and Tomorrow tabs (owner, October 19; built October 19).
6. [x] **Mirror and Settings after the owner's check.** Done October 18. Owner decisions, October 18:
   - Tapping a palette colour opens its name, the nearest of 78 clothing colours (`ColourNames`), and how to wear it.
   - "See your full analysis" opens the whole skin analysis as a sheet: the colours read from the photo, what the undertone, depth and contrast mean, and the season.
   - An outfit in the wardrobe takes one or more colours.
   - Fixed: Settings' profile square showed bare Rose after the face photo was replaced in Mirror, because Settings still held the deleted file's path. It now reloads whenever its tab is shown, and the initial stands in for a photo that can't be drawn.
   - Found on the way: error reports held only "String" for a failed YouCam task; they now carry its code, and a network failure's kind. Widget publishes run one at a time, so two can't delete each other's pictures.

**Also open:**

- [ ] **Recommender v2** (owner, October 19). Built October 19 on stacked branches, not merged: the catalog in the app (`feat/catalog_v2`), the recommender (`feat/stylist_engine`), Home's days on it with the old system and its `in-vogue-dev` records gone (`feat/stylist_on_home`), the taste model (`feat/stylist_signals`) and the wardrobe on Home (`feat/wardrobe_on_home`), as the design's delivery plan (§13 of `../docs/recommender-design.md`, outside the repository) plans. *Blocked on the owner's device run and merge go-ahead.*
- [ ] Build and check both home-screen widgets on phones. *Owner.*
- [ ] The first real YouCam run, and the device run of the October 17 work. *Owner.*
- [ ] Open a sample of Everlane product links. *Owner.*
- [ ] Membership rules for the MVP. *Blocked on the owner.* Then the Free-plan limits, the Go Pro screen and the Free-plan locks.
- [ ] How testers get the app. *Blocked: the owner picks the channel* (Firebase App Distribution recommended).
- [ ] "Other outfits" on Home. *Blocked on the owner.*
- [ ] Holiday and evening occasions. *Blocked on owner input.*
- [ ] Review the copy, every word in the app, in all three languages (owner, October 18). *Owner.*
- [ ] A landing page with the terms, a privacy policy, issue reporting, SEO and a wishlist (owner, October 18). *Owner.*
- [ ] Link the landing page's terms, privacy policy and issue reporting from the app. *Blocked on the landing page.*
- [ ] How long to keep old pictures and records. *Blocked on the owner.*
- [ ] Keep the catalog fresh. *Pending; ask first, because a rebuild reshuffles outfits.*
- [ ] Run each skill's evals and record them below. *Pending; ask first, because it uses subagents.*
- [ ] Push to `origin`. *Blocked on the owner's go-ahead.*

### Roadmap

- Plan ahead: choose a future date and an occasion, and In Vogue dresses you for that day's forecast once the forecast reaches it.
- Move the YouCam key into a Firebase Cloud Function: the key in Secret Manager, callable functions for the four keyed calls (create an upload, start a task, check it, delete it) that answer only signed-in people and only for `cloth-v4` and `skin-tone-analysis`, and the app calling them from both flavors. Production builds can then make outfits too.

### Production checklist

The production flavor (`com.invogue.app`, Firebase `in-vogue`) needs these before release:

- [ ] Check that the Firestore `(default)` database and Storage exist in `in-vogue` (Storage needs the Blaze plan).
- [ ] Deploy `firestore.rules` and `storage.rules` to `in-vogue`.
- [ ] Turn on the Apple and Google providers in Firebase Auth for `in-vogue`.
- [ ] Create the Android release key and `android/key.properties`, add its SHA-1 and SHA-256 to the `in-vogue` Android app, then refresh the native files with `scripts/configure_firebase.sh production`.
- [ ] iOS: Sign in with Apple for `com.invogue.app`, distribution signing and an App Store Connect record.
- [ ] The YouCam key from the Cloud Function above.
- [ ] Keep the YouCam account funded.
- [ ] A privacy policy, the App Store privacy details and Google Play's data-safety form.
- [ ] The iPhone widget for production: entitlements for the app and the extension with `group.com.invogue.app`, `HomeWidgetDataSourceImpl.appGroupOf(production)`, and the extension's version and build number matching the app's.
- [ ] Build the production flavor and check sign-in, the first outfit, Mirror's colours and Delete account on a device.
- [ ] Sign the release builds and upload them to the stores.

## Skills

Each lives in `../.claude/skills/<name>/`: a `SKILL.md`, optional `references/` and `evals/evals.json`. A session started in `weather-dot-me/` loads them; one started in `in-vogue/` doesn't, so read the matching `SKILL.md` when a task enters its area.

| Skill | Use it for | Evals |
| --- | --- | --- |
| `verifying-changes` | the check loop and honest reporting | not run |
| `writing-tests` | tests the owner's way; how each package is mocked here | not run |
| `building-features` | Clean Architecture slices, DI, routing, stand-ins; the feature map | not run |
| `building-ui` | the design system, the spec and the owner's overrides, copy, motion, accessibility | not run |
| `calling-youcam` | try-on, the skin-tone analysis, photo errors, costs, keys and the owner's YouCam rules | not run |
| `managing-firebase` | the data model, rules, sync, account save, restore and delete | not run |
| `updating-bundled-data` | the shop's catalog pull, its export for Shop, and the curated outfit catalog's build and upload | not run |
| `building-home-widgets` | both home-screen widgets: content, day rule, taps, native code, the morning refresh | not run |

New skills follow Anthropic's method: write three eval prompts first, then the smallest `SKILL.md` that passes them, validate it with `quick_validate.py` from the skill-creator skill, and test it with and without the skill.
