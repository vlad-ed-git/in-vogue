# AGENTS.md

In Vogue is a Flutter weather app for Android and iPhone. Each day it shows the person, head to toe, in a real outfit from a partner catalog (Everlane today) picked for the day's weather and occasion, with step-by-step makeup to match, a link to buy each piece and a home-screen widget.

- **Read [README.md](README.md)** for the system design, architecture, data model and APIs. Area details are in the skills (below).
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

The other commands (data exports, widget glyphs, Firebase rules and native files, the development YouCam key, launcher icons) are in README's [Commands](README.md#commands).

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
- Run `flutterN build`, `flutterN run`, simulators or `integration_test/` unless asked. The owner's device runs are the native check.
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
5. Update the docs in the same task: tick Open work, record owner decisions (rules here, how things work in README) with the date, and update any skill whose facts changed.

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
- Clothes only: no shoes, bags or accessories, and people keep their own shoes. Face makeup only, never hair.
- Outfits come from the whole collection. Loved pieces add weight; never-suggested outfits come first, then the one suggested longest ago.
- English unless the person picks another language; never follow the phone's.

**Not building** (owner decisions): servers, webhooks or schedulers · a units cap or kill switch · a guest outfit · photo detection · the camera · dark mode · partner credits · loading the catalog from Firebase (it stays bundled) · enforcing App Check · wardrobe uploads, AI chat, social features, calendar or trip planning, quizzes, skin reports, hair changes, in-app checkout or endless feeds.

## Security

- `secrets/` is git-ignored. It holds the YouCam key and secret and the development Firebase admin key. `assets/development/youcam_api_key.txt` is git-ignored too: development builds bundle it, production builds never do. The native Firebase files are git-ignored. Never print, log or commit any of them.
- Firestore and Storage rules give each person only `users/{uid}/**`, and nobody can change their own `plan`. The one exception is `errors`, where a signed-in person may only add their own report. Check a rules change on the emulator before deploying it to development.

## Open work

*Pending* means nothing blocks it. *Blocked* names who it waits on. Details are in README's [Roadmap](README.md#roadmap); the production release has its own [checklist](README.md#production-checklist).

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

## Skills

Each lives in `../.claude/skills/<name>/`: a `SKILL.md`, optional `references/` and `evals/evals.json`. A session started in `weather-dot-me/` loads them; one started in `in-vogue/` doesn't, so read the matching `SKILL.md` when a task enters its area.

| Skill | Use it for | Evals |
| --- | --- | --- |
| `verifying-changes` | the check loop and honest reporting | not run |
| `writing-tests` | tests the owner's way; how each package is mocked here | not run |
| `building-features` | Clean Architecture slices, DI, routing, stand-ins; the feature map | not run |
| `building-ui` | the design system, the spec and the owner's overrides, copy, motion, accessibility | not run |
| `calling-youcam` | try-on, face analysis, makeup calls, costs, keys and the owner's YouCam rules | not run |
| `managing-firebase` | the data model, rules, sync, account save, restore and delete | not run |
| `updating-bundled-data` | the catalog and knowledge-base pipeline and the asset exports | not run |
| `building-home-widgets` | both home-screen widgets: content, day rule, taps, native code, the morning refresh | not run |

New skills follow Anthropic's method: write three eval prompts first, then the smallest `SKILL.md` that passes them, validate it with `quick_validate.py` from the skill-creator skill, and test it with and without the skill.
