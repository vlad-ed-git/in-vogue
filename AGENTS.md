# AGENTS.md: In Vogue

The single source of truth for anyone, human or AI, working on In Vogue. Last checked against the code on **October 17, 2026** (branch `feat/logout_clears_pictures`). It replaces the earlier version of this file and the workspace's old `checkpoint.md` and `plan.md`. Keep it true (§1.8).

**In Vogue** is a weather app with a home-screen widget. Every day it shows the person, head to toe, wearing a real outfit from a partner fashion brand that suits that day's weather and plans. It adds step-by-step makeup to match and a link to buy each piece. We are building a **scalable, production-ready MVP**. The current partner catalog is Everlane's women's collection. Rights to the catalog and brand content are in place, so the work is engineering.

| Workspace folder (`/Users/vlad/Desktop/vlad/mine/weather-dot-me/`, not a git repo) | What it is |
| --- | --- |
| `in-vogue/` | The Flutter app, and the only git repository |
| `design-spec/` | The design specification. Read-only |
| `resources/` | The clothing catalog, the knowledge base and their Python tools |
| `.claude/skills/` | Skills for the AI (§4) |
| `app certs and profiles/` | The owner's signing files. Don't touch |

This file lives in `in-vogue/`. Its paths are relative to the workspace root unless a command runs from `in-vogue/`. A session started in `in-vogue/` loads this file at the start, but not the skills in `weather-dot-me/.claude/skills/`. A session started in `weather-dot-me/` loads the skills at the start, and loads this file once Claude reads a file inside `in-vogue/`.

---

## 1. How to work here

### 1.1 Golden rules

1. **Think logically about what you are doing** (the owner's own words). Before you build something, check it against the product rules, the costs and how it could be abused, not only against an older plan. For example, nothing calls YouCam before sign-in, because anonymous use would spend units with nobody to track them.
2. **Plan, then build.** For a task with more than one step, first write down what is wrong today, the design, the tests and the build order (1a, 1b, …). Ask the owner only the decisions that are really theirs. Then build one step at a time, each with its tests and commits.
3. **Build in screen order.** If a screen needs a service that doesn't exist yet, give it an honest **stand-in**: a placeholder that says "not available yet" and never fakes success. Never undo or scale back work that is already done.
4. **The owner's latest decision wins**, over older notes, the design spec's mockups and your own ideas. If something you remember conflicts with this file, this file wins.
5. **Ask before swapping.** If a package or approach the owner named doesn't work, stop and offer 2–3 options with a recommendation. Never quietly substitute your own. Version conflicts are different: see §1.4.
6. **Be plain and honest.** Say what you are about to do before long steps. Report real results: exact test counts, real failures, skipped steps.

### 1.2 Commands

Run every Flutter and Dart command from `in-vogue/` through an interactive zsh, because `flutterN` is a shell alias. Use `flutterN`, never `flutter` (owner rule). Some SDK, network and git commands need the sandbox lifted.

| Task | Command |
| --- | --- |
| Get packages | `zsh -ic 'flutterN pub get'` |
| Generate translations (after editing `.arb` files) | `zsh -ic 'flutterN gen-l10n'` |
| Generate Mockito mocks | `zsh -ic 'dart run build_runner build --delete-conflicting-outputs'` |
| Format | `zsh -ic 'dart format lib test integration_test test_visual'` |
| **Analyze** | `zsh -ic 'flutterN analyze'` |
| **Test** (everything, about 1 minute) | `zsh -ic 'flutterN test'` |
| Test one file | `zsh -ic 'flutterN test test/features/outfits/make_outfit_test.dart'` |
| Visual boards (optional) | `zsh -ic 'flutterN test test_visual'`, which writes PNGs to `build/visual/` |
| Re-export bundled data | `python3 scripts/export_catalog.py`, then `export_outfits.py`, then `export_makeup.py` |
| Write the dev YouCam key file | `python3 scripts/write_development_defines.py` |
| Deploy rules (development only) | `GOOGLE_APPLICATION_CREDENTIALS="$PWD/secrets/in-vogue-dev-firebase-adminsdk-fbsvc-517e1ce146.json" firebase deploy --only firestore:rules,storage --project in-vogue-dev --non-interactive` |
| Native Firebase files | `scripts/configure_firebase.sh development` (or `production`) |
| Launcher icons | `scripts/generate_app_icons.sh` |

A task is **done** only when analyze says "No issues found!" and every test passes.

**Don't run these unless the owner asks:** `flutterN build …`, `flutterN run`, simulators, `integration_test/`. They take minutes, and the owner's own device runs are the native check.

### 1.3 Git

- The app repository is `in-vogue/` (remote `origin` = github.com/vlad-ed-git/in-vogue). The workspace root is not a repo; don't make it one.
- Work on a feature branch. Make small commits, each about one area, with a scoped subject, for example `feat(outfits): …`, `fix(account): …`, `refactor(…)`, `test(…)`, `chore(firebase): …` or `docs: …`. Plan the commit groups before a multi-part task, and keep each part's commits together. If history ever needs regrouping, rebuild it on a new branch with cherry-picks, and check the final tree is identical before moving the branch.
- **Never add an AI co-author** (no `Co-Authored-By` line).
- **Never push, and never merge into `main`, without the owner's go-ahead.**
- The owner commits too. Read before you edit, and never overwrite their work. When CocoaPods rewrites `project.pbxproj` to object version 54, keep the Xcode-saved version.
- No GitHub workflows and no CI/CD of any kind. All checks run locally.

### 1.4 Code

- **Architecture:** feature-first Clean Architecture. `domain` is pure Dart, then comes `data`, then `presentation` (BLoC), and `di` wires it all with GetIt. Hive keeps small values on the phone and SQLite keeps the cache. Results are `Either` (dartz) and values use Equatable. Write the test first (red, then green).
- **Text on screen:** read it through `context.translated.<key>` from `lib/l10n/arb/app_en.arb` (the default), `app_es.arb` and `app_zh.arb` (Simplified Chinese). Every string goes into all three files.
- **Comments:** short, saying what the code is or does. Never say where it's used, and no product stories.
- **Packages:** always the newest version, and never downgrade. Settle version clashes yourself with `dependency_overrides` plus a one-line reason, without asking.
- **Tests:** test our app, never the packages. Mock each package the way its own docs say. A thin wrapper around an SDK gets no tests. Tests never call YouCam or real Firebase.
- **Screens:** each app screen is its own screen. Never reuse a setup screen; share widgets instead.
- **Platform setup is the owner's job:** Xcode capabilities, entitlements, signing, URL types and Firebase or Apple console settings. Give the owner an exact list and don't hand-edit. For a simple package, follow its README rather than digging through its source.

### 1.5 Product rules: never break these

- The app is **In Vogue**. Never write its old working name anywhere.
- **No clothing prices anywhere.** The only price in the app is on Go Pro: $7.99 a month or $59.99 a year.
- **Photos are uploaded, never taken:** from Photos (iOS) or Gallery (Android) only. No camera, and never the words "take a photo". Trust the person's photo: no detection or checking of any kind beyond the size and format rules.
- **YouCam:** no call before sign-in. **No units cap or counter, ever.** Everything runs in the app: **no Cloud Functions or servers.** **You never spend units yourself**; real YouCam runs are the owner's.
- **No partner credits.** Never show "AI preview · Outfits by {Brand}" or "Outfits by {Brand}"; "Buy at {Brand}" is fine. In Vogue is its own brand presenting many partner houses. Everlane is the current partner catalog, and no design decision is ever based on a partner.
- **One white theme.** Never dark mode, a theme switch or an appearance setting. `design-spec/` is read-only. When the app follows a newer owner decision, record it here, not in the spec.
- **Clothes only:** no shoes, bags or accessories, and the person keeps their own shoes in try-ons. **Face makeup only:** never hair.
- **Outfits come from the whole collection.** Loved pieces only add weight. Outfits never suggested before come first; once all have been suggested, the one suggested longest ago comes back.
- **Rights to the catalog and brand content are already in place.** Don't raise licensing; focus on engineering.

### 1.6 Secrets

`in-vogue/secrets/` is git-ignored. It holds `youcam_api.txt`, `youcam_secret.txt`, `development.json` and the development Firebase admin key. **Never print, log or commit any of them.** The native Firebase files (`google-services.json`, `GoogleService-Info.plist`) are git-ignored too.

### 1.7 Other projects

Kostuma (`/Users/vlad/Desktop/vlad/mine/kostuma/kostuma`) and Utano (`/Users/vlad/Desktop/vlad/mine/utano_apps`) are read-only references. Never touch their code, keys, YouCam credits or data.

### 1.8 Keep this file true

At the end of every task:

- Tick what's done in §3 and move it into §2, with the date.
- Write new owner decisions into the right section, with the date, and delete what they replace. Don't stack old and new.
- Change numbers (like the test count) only after a real run.
- If a skill's facts changed, update that skill in the same task.
- Put an agreed plan under its §3 item as sub-steps. Don't create separate checkpoint or plan files.

---

## 2. What is built

Checked on October 17, 2026, by reading the code and running the checks: **`flutterN analyze`: no issues. `flutterN test`: 749 tests pass.** Everything below runs on the development **flavor** (the app's development build, using Firebase project `in-vogue-dev`).

### 2.1 What a person can do today

| Part | What works |
| --- | --- |
| **Setup**: six screens that reopen where you left off | **1 Welcome:** the logo, "Use my location" (approximate location only) and a language icon. **2 Your photo:** a full-body photo from the gallery. **3** Tomorrow's weather, plus a few pieces you like (hearts). **4** Sign in with Apple (iPhone only) or Google. **5 About you:** your name (filled in when Apple, Google or your old account knows it) and an optional face photo. **6 Add the widget:** a *stand-in*, because the widget isn't built. Android's button says it isn't ready, and iPhone shows the three steps. |
| **Home tab** | City and ♡ Your picks at the top, then a Today / Tomorrow / Outfits switch (tap or swipe). The weather that matters: temperature, feels-like, rain timing and strong wind. The occasion (Work, Casual, Going out, Staying in) with Change. Then the person wearing the day's outfit, or "Getting your outfit ready… Piece n of N", or why it failed, with Try again. Below that, Shop and "About this outfit". **Outfits** shows the whole collection grouped by weather (Hot, Warm, Mild, Cool, Cold, Rain), with hearts. |
| **Shop** | Every piece of the outfit: photo, colour, name, material and "Buy at Everlane", which opens that exact item on Everlane's site. No prices. |
| **Your picks** | Only the pieces you loved. Removing one asks first. |
| **Makeup tab** | It follows Home's day and occasion. Once there is a face photo and an outfit, the look starts by itself: Before / After, one sentence tying it to the outfit, and 3–6 numbered steps showing your face after each step (tap to zoom). Steps appear as they finish. |
| **Settings** | Profile (face photo, name, how you signed in, edit name; without a face photo, the name's first letter in white on a Rouge square set like the logo's "In", added October 17), replace the body or face photo, membership (shows Pro or Free; display only), location (Change), default day (tomorrow with the morning rule, or always today), language, Log out (it also clears the account's outfit and makeup pictures from this phone, keeping the body and face photos and the picks; added October 17), and Delete account, which removes the account's data from Firebase and from this phone. |
| **Languages** | English (the default), Spanish and Simplified Chinese. The exception is the knowledge base's texts (makeup steps, outfit reasons), which are English only. |

The day rule: Home opens on **tomorrow**, except from **06:00 to 08:59**, when it opens on today. The occasion defaults to **Work on weekdays and Casual at weekends**.

### 2.2 How it works underneath

- **Outfits.** 1,749 ready-made outfits from the knowledge base are bundled in the app, sorted into 96 *cells* (a weather class combined with an occasion). For each day the app picks one: outfits never suggested come first, scored 80% on the knowledge base's rank and 20% on how many of the pieces you loved; after that, the one suggested longest ago. It then *claims* the day in Firestore in an all-or-nothing write (a transaction), so two phones, or today and tomorrow, never clash. YouCam then dresses the person **piece by piece**: bottom, then top, then outer layer; a dress goes in one pass. Progress is saved after each piece. Another phone takes over if nothing changes for 10 minutes, and an interrupted job resumes within 2 hours. The finished picture is kept on the phone and in Firebase Storage.
- **Makeup.** YouCam reads the face's colours once per face photo, and the result is kept in Firestore under the photo's fingerprint. The app turns those colours into a skin profile (shade group and contrast) and picks one of 720 recipes, chosen by occasion, outfit palette, shade, contrast and weather. YouCam then applies each step on top of the previous step's picture. Skin smoothing is always off.
- **Photo rules.** Every chosen photo is checked. If it's too small, the app asks for another. If it isn't JPEG or PNG, it is converted to PNG and the app shows a note. If it's too big, it is scaled down. There is no face or body detection.
- **Account.** The profile, favourites, photos and records live in Firestore (Firebase's database) and Storage (Firebase's file store) under `users/{uid}`. Each person can reach only their own data; the rules are deployed to `in-vogue-dev`. A returning person gets their name, face photo and favourites back at sign-in. Saving never wipes favourites, and photos are replaced only when their content changes. **Every new account is created on the Pro plan** (set in `features/account/data/models/account_model.dart`).
- **Weather.** Open-Meteo (no key), cached for 2 days. Offline, the app shows the saved forecast with a note. °F in the US, °C elsewhere.
- **Foundation.** Two flavors: development uses `in-vogue-dev` and production uses `in-vogue`, with a startup check that the flavor and project match. Hive and SQLite on the phone. The design system in `lib/core/presentation/` (tokens, theme, 28 components) matches the spec, including the curtain reveal of a new outfit. Launcher icons are made from the logo. Errors are logged only in debug builds (`LogMessagesImpl`), so release builds report nothing yet.
- **Data tools.** These live outside the app, in `resources/`: the Everlane catalog pull (from Shopify's Global Catalog), the knowledge base (weather, occasions, styling, outfits, skin, makeup, YouCam reference) and their Python builders. `in-vogue/scripts/export_*.py` copies what the app needs into `assets/`.

### 2.3 Where the code is

| Branch | Holds | State |
| --- | --- | --- |
| `main` | Foundation, design system, setup flow, sign-in, log out | 60 commits ahead of `origin/main`; not pushed |
| `feat/first_outfit` | Everything in `main`, plus the account, the first try-on, Home, Shop and Settings | Not merged, not pushed |
| `feat/makeup` | Everything in `feat/first_outfit`, plus the Makeup tab, two-day outfits in Firestore, photo rules, returning users and makeup that starts by itself | Not merged, not pushed |
| `feat/settings_profile_initial` | Everything in `feat/makeup`, plus Settings' default profile picture | Not merged, not pushed |
| **`feat/logout_clears_pictures`** (current) | Everything in `feat/settings_profile_initial`, plus log out clearing the phone's outfit and makeup pictures | Not merged, not pushed |

The owner committed the `ios/Podfile.lock` update for the new Firebase pods on October 17 (`cleanup`).

### 2.4 What has been checked on a real phone

- Confirmed by the owner on October 16: Google sign-in works, and an Apple sign-in saved the profile, both photos and 4 favourites to Firebase.
- **Not yet checked against the real YouCam API.** The last record (October 17) says no real call had been made: try-on and makeup have only run on test fakes. If the owner has run them since, update this line.
- The October 17 work (two-day outfits, photo rules, returning users, makeup by itself) is waiting for the owner's device run.

---

## 3. What is left

**Pending** means nothing blocks it; it just isn't done. **Blocked** means it waits on the person or decision named. Tick `[x]` when done and move the item to §2.

### 3.a What's left to build

**App features**

- [ ] **Home-screen widget for Android.** *Pending, not started.* The widget is the product's front door. It shows the day's outfit picture and weather in the Large, Medium and Small layouts of `design-spec/components/HomeWidget`: a print, with a Rouge slab and the full-height portrait running edge to edge, never a rounded card (the owner rejected one). It opens Home on tap, and setup step 6 then really places it. Agree a plan with the owner first, especially how the widget gets a fresh picture while the app is closed. Native builds are the owner's.
- [ ] **Home-screen widget for iPhone (WidgetKit).** *Blocked on the owner's Xcode setup* (widget extension target, App Group, signing). The AI writes the code and gives the owner the exact steps.
- [ ] **Membership rules for the MVP.** *Blocked on an owner decision.* The plan so far (October 14): Free gives 14 outfits and 3 makeup looks over the account's whole life, never reset, and one outfit a day. Pro is shown at $7.99 a month or $59.99 a year. Go Pro adds the person to a waiting list, with no payments. Today every new account is created Pro. Confirm these rules for production, including whether Pro takes real payments.
- [ ] **Free-plan limits.** *Pending, after the decision above.* Count outfits shown and makeup looks made; an outfit counts once however many YouCam calls it took, and replacing a photo resets nothing. When they run out, the last outfit stays on screen with Go Pro.
- [ ] **Go Pro screen.** *Pending, after the decision above.* "In Vogue Pro", four benefits and the price. Go Pro joins the waiting list and shows "You're on the list" with a drawn check, and every Go Pro afterwards reads "On the Pro list ✓". The design-system pieces already exist (`ProOffer`, `ProConfirmation`, `PlanLine`, and locked `ProductTile` and `OutfitTiles`). The list must live under `users/{uid}`, or the rules need changing.
- [ ] **Free-plan locks.** *Pending, after the decision above.* The plan line at the bottom of Home, Settings' membership row with Go Pro, and browsing limited to about 30 current-season pieces.
- [ ] **"Other outfits" on Home** (Pro: up to 3 more outfits a day; tapping one swaps it in at once). *Blocked on an owner decision.* Home's switch became Today / Tomorrow / Outfits on October 16, and each extra outfit is a full try-on (4–6 units).
- [ ] **Translate the knowledge base's texts** (makeup step titles, how-tos and product kinds, and outfit reasons) into Spanish and Chinese. *Pending; owner to-do from October 17.*
- [ ] **Holiday and evening occasions.** *Blocked on owner input.* Public holidays should count as casual days, which needs a dated holiday list for each supported country. Still open: whether evenings default to Staying in (Monday to Thursday) and Going out (Friday to Sunday).
- [ ] **Favourites across phones.** A favourite removed on one phone can come back from another. *Pending, low priority.*
- [ ] **Skip an outfit that YouCam refuses for its reference photo** (`error_invalid_ref`), instead of retrying the same one. *Pending, low priority.*
- [ ] **Trim the on-screen wording.** *The owner leads this;* they find the copy too wordy.

**Production readiness**

- [ ] **Stop people upgrading themselves.** *Pending.* Today the rules let a signed-in person write anything in their own `users/{uid}`, including `plan`, so anyone could make themselves Pro. Tighten `firestore.rules` so the app can't change `plan` (and, once the limits exist, can't lower the counters), then deploy. Without a server, counters kept by the app can never be fully tamper-proof; tell the owner.
- [ ] **Crash and error reporting.** *Pending; the owner picks the tool* (Firebase Crashlytics fits the stack). Release builds report nothing today.
- [ ] **Old pictures and records.** *Pending; the owner picks how long to keep them.* Each active person adds two outfit pictures, makeup pictures and day records every day, and only Delete account ever removes them. A Storage lifecycle rule and Firestore TTL policies can clean up without a server. Never expire `suggestions`, because they drive the no-repeat rule.
- [ ] **How the catalog and knowledge base reach the app.** *Blocked on an owner decision.* They are bundled in `assets/`, so every catalog change (new stock, a new partner brand) needs an app release. To scale to many partners, decide whether to load versioned catalog and knowledge-base files from Firebase instead.
- [ ] **Keep the catalog fresh.** *Pending.* The catalog is a snapshot from October 14. Re-run the pull and the exports regularly, and mark pieces that are no longer for sale on Shop instead of sending people to a dead page.
- [ ] **Firebase App Check.** *Pending; needs the owner's console setup* (App Attest on iOS, Play Integrity on Android), so only the real app can reach Firestore and Storage.

**Checks only the owner can do**

- [ ] **The first real YouCam run** (try-on and makeup end to end on a device). *Blocked on the owner*, because only the owner spends units.
- [ ] **A device run of the October 17 work**: two-day outfits, photo rules, returning users and makeup by itself. *Blocked on the owner.*
- [ ] **Open a sample of Everlane product links** in a browser and check each opens the right item. Everlane blocks this Mac, so they were never opened here. *Owner.*

**Housekeeping**

- [ ] Merge `feat/makeup` into `main`. *Blocked on the owner's go-ahead.*
- [ ] Push to `origin`. *Blocked on the owner's go-ahead.*
- [ ] Bring `in-vogue/README.md` up to date: its intro and folder tree still describe October 16. *Pending.*
- [ ] Run each skill's evals in fresh sessions, with and without the skill, and record the results in §4.1. *Pending.*

### 3.b Production release checklist

Development is the everyday flavor. These steps make the **production** flavor (`com.invogue.app`, Firebase `in-vogue`) ready to release.

- [ ] Check that the Firestore `(default)` database and Storage exist in `in-vogue` (Storage needs the Blaze plan). They exist in development; production hasn't been checked. *Owner.*
- [ ] Deploy `firestore.rules` and `storage.rules` to `in-vogue`. *Owner;* the AI's admin key works for development only.
- [ ] Turn on the Apple and Google providers in Firebase Auth for `in-vogue`. *Owner.*
- [ ] Create the Android release key and the git-ignored `android/key.properties` (see `android/key.properties.example`). Add the key's SHA-1 and SHA-256 to the `in-vogue` Android app in Firebase. *Owner.*
- [ ] After the two steps above, refresh production's native Firebase files with `scripts/configure_firebase.sh production`. *AI or owner.*
- [ ] iOS: the Sign in with Apple capability for `com.invogue.app` (team `Q56R6X96PZ`), distribution signing, and an App Store Connect record. Production's Google URL scheme is already in the project. *Owner.*
- [ ] **Decide how production gets the YouCam key.** *Blocked on the owner.* Production passes no key today, so it makes no outfits or makeup. The simple option works like development: a git-ignored secrets file passed with `--dart-define-from-file`. Note that a key inside an app can be extracted. No Cloud Functions (owner, October 17).
- [ ] Keep the YouCam account funded for production use. When its units run out, outfits and makeup stop for everyone ("No more outfits can be made for now."). *Owner.*
- [ ] The store requirements for the chosen channel: a privacy policy, the App Store privacy details and Google Play's data-safety form. Photos go to YouCam and Firebase. *Owner.*
- [ ] The widget built and checked on both platforms (§3.a).
- [ ] Build the production flavor and check on a device: Apple and Google sign-in, the first outfit, makeup and Delete account. *Owner.*
- [ ] Release builds signed with the release keys, uploaded to the chosen channel (TestFlight, App Store, Google Play). *Owner.*
- [ ] Merge to `main`, push and tag the release. *Owner's go-ahead.*

### 3.c Dropped: don't build these (owner decisions)

Cloud Functions, servers, webhooks or schedulers · any YouCam units cap, counter, quota or kill switch · a guest outfit, or any YouCam call before sign-in · face or body detection on photos · the camera · dark mode or a theme switch · partner credit lines · the rolling temperature (replaced by a sideways shift) · category chips on the picks screen · the "You've seen every outfit" dead end · wardrobe uploads, AI chat, social features, calendar or trip planning, quizzes, skin-health reports, hair changes, in-app checkout and endless feeds.

---

## 4. Skills (for the AI)

A skill is a folder of instructions that Claude Code loads only when a task needs it (Anthropic's Agent Skills). Only each skill's name and description are always in context. The body loads when the task matches, and reference files load only when opened. That is how this file stays short while the details stay available.

### 4.1 Skills in place

They live at `weather-dot-me/.claude/skills/<name>/`, each with a `SKILL.md`, optional `references/` and an `evals/evals.json` holding three test prompts. All seven pass Anthropic's `quick_validate.py`.

| Skill | Use it for | Evals |
| --- | --- | --- |
| `verifying-changes` | the local check loop and honest reporting | written, not run |
| `writing-tests` | tests the owner's way; how each package is mocked here | written, not run |
| `building-features` | Clean Architecture slices, DI, routing, stand-ins; the feature map | written, not run |
| `building-ui` | the design system, the spec and the owner's overrides of it, copy, motion, accessibility | written, not run |
| `calling-youcam` | try-on, face analysis, makeup calls, costs, keys and the owner's YouCam rules | written, not run |
| `managing-firebase` | the data model, rules deploys, sync, account save, restore and delete | written, not run |
| `updating-bundled-data` | the catalog and knowledge-base pipeline and the asset exports | written, not run |

Also available, from the owner's personal skills in `~/.claude/skills/`: `logo-design`, for logo and app-icon work.

### 4.2 How to obtain a new skill (Anthropic's recommended method)

```
- [ ] 1. Do the task without a skill. Note what you had to look up, and every correction the owner made.
- [ ] 2. When the same context is needed a second time, or the owner corrects the same thing twice, it's a skill.
- [ ] 3. Write 3 realistic test prompts first, in evals/evals.json:
         {skill_name, evals: [{id, prompt, expected_output, files, expectations}]}.
         Record how a fresh session does without the skill (the baseline).
- [ ] 4. Write the smallest SKILL.md that closes the gaps:
         name: lowercase-and-hyphens, 64 chars at most, gerund form (building-widgets), no "claude" or "anthropic".
         description: third person; what it does and when to use it, key use first; 1,024 chars at most; no angle brackets.
         Body under 500 lines. Details go in references/*.md linked straight from SKILL.md (one level deep;
         a table of contents if a file passes 100 lines). Scripts for anything deterministic. No dated "before X" text.
- [ ] 5. Validate: python quick_validate.py <skill-dir>, from the skill-creator skill (needs PyYAML; use a scratch venv).
- [ ] 6. In a fresh session, run the eval prompts with and without the skill. Watch which files it reads, and tighten.
         Test on every model you use: Haiku needs more detail, Opus less.
- [ ] 7. Add it to §4.1. Whenever code changes a skill's facts, update the skill in the same task.
```

The `anthropic-skills:skill-creator` skill automates steps 3–6: test runs, grading, a review viewer and description tuning.

### 4.3 Skills to obtain next

| Skill | Obtain it | Because |
| --- | --- | --- |
| `building-home-widgets` | during the first widget task (§3.a) | the `home_widget` bridge, the Android widget, WidgetKit, App Groups, refresh limits |
| `diagnosing-device-reports` | the next time the owner reports a bug from a device | the repeating pattern: a full restart after native plugins, Firebase error codes in logs, read-only admin checks |
| `releasing-builds` | when the production checklist (§3.b) starts | signing, store and TestFlight uploads, the hand-offs to the owner |
| `translating-copy` | if the knowledge-base translation outgrows `updating-bundled-data` | the ARB and knowledge-base translation workflow |

---

## 5. Knowledge base (for the AI)

Facts that aren't obvious from the code. The skills hold the details.

**Identity and tools**
- App IDs: `com.invogue.app.dev` ("In Vogue Dev") and `com.invogue.app` ("In Vogue"). Firebase projects: `in-vogue-dev` and `in-vogue`. Development is the everyday flavor, and plain `flutterN run` uses it. A flavor that doesn't match its Firebase project fails at startup.
- Apple team: Conduct Wellness Pal Co. Ltd., `Q56R6X96PZ`. Google iOS URL schemes: development `com.googleusercontent.apps.184104161725-h701r3ame556n3gnng2fgppa84sfp5ig`, production `com.googleusercontent.apps.854510811606-n3o3e82qpcks173om632be5bqjqq17ne`. Android development debug SHA-1 `14:66:6A:…:E2:D5` is registered in development.
- Tools: Flutter 3.44.4 and Dart 3.12.2 (`/Users/vlad/Development/flutter`), Xcode 26.3, CocoaPods 1.16.2 (plugins through CocoaPods, not SPM; open `ios/Runner.xcworkspace`), Java 17, iOS 15.0+, Android minSdk 24, FlutterFire CLI 1.4.0, Firebase CLI at `/opt/homebrew/bin/firebase`, ImageMagick `magick`.
- `.vscode/launch.json` holds both flavors; the development configuration passes `--dart-define-from-file=secrets/development.json`.

**Product logic**
- Welcome's tagline: "Meet tomorrow's weather in style."
- Language: English unless the person chose another; it never follows the phone. It is restored before the first frame.
- Weather class: the feels-like band of the window's **coldest** hour (hot, warm, mild, cool, cold) × precipitation (dry, wet, snow; snow only when cool or cold; drizzle counts as dry) × wind (gusts of 39 km/h or more are windy). That makes 24 classes × 4 occasions = 96 cells, keyed `band|precipitation|wind|context`, with 29–100 outfits each.
- Day records: `making`, then `ready` or `failed`. The lease is 10 minutes and a try-on job is valid for 2 hours. Today and tomorrow never share an outfit. A day keeps its outfit even if the forecast later moves it to another cell.
- Makeup: the shade group comes from ITA° (light from 41°, medium from 10°, deep below; within 2° above an edge counts as the deeper group). Contrast is ΔL* between the skin and the darker of brows and hair (medium from 25, high from 45). Concealer is the skin's OKLab L +0.03; nude lip is the lips' L −0.03 with chroma ×0.9. A photo that isn't clear gets neutral medium/medium. Looks have 3 steps for Staying in, 4 for Casual, 5 for Work and 6 for Going out.
- Photos: JPEG or PNG, at most 10 MB and 4096 px. Body photos need at least 512 × 384, face photos at least 320 px a side. The picker scales to 2048 px at JPEG quality 90.
- YouCam costs: 2 units per try-on pass, 20 per face analysis, 1 per makeup step; failed tasks are free. One new person's first day costs about 2 outfits × 4–6 units, plus 20 for the face analysis, plus 3–6 per makeup look. Balance on October 16: 40 units, expiring 2027-10-16.

**History, so old ideas stay dead**
- October 14: screen-by-screen walkthrough. Everlane's women's collection became the first catalog. Piece-by-piece try-on was chosen, with fallback B (Everlane's whole-outfit photos) held in reserve.
- October 15: the design became Swiss Style on white with Rouge and Rose (magenta, ultramarine and full colour fields were rejected), and the logo was finalised. `phosphor_flutter` broke on Flutter 3.44, so the owner chose `phosphoricons_flutter`.
- October 16: setup reordered (photo before sign-in, no guest outfit). "JUST TRUST THE USER": no photo checks. No native builds unless asked. Never test packages. No screen reuse. The temperature roll was removed.
- October 17: no units cap ever, everything in the app, newest package versions without asking, and makeup starts by itself. This file replaced `checkpoint.md` and `plan.md`. The focus became a scalable, production-ready MVP, with rights to the catalog and brand content in place.

---

## 6. System design

**The big picture**

```
                  ┌─────────────── the phone: In Vogue (Flutter) ────────────────┐
Open-Meteo  ◄─────┤ weather (dio; cached 2 days in SQLite)                        │
YouCam API  ◄─────┤ try-on · face colours · makeup steps   (signed in; dev key)   │
Firebase    ◄─────┤ Auth (Apple, Google) · Firestore users/{uid} · Storage        │
Everlane    ◄─────┤ "Buy at Everlane" opens the exact item (url_launcher)         │
                  │ bundled: catalog · 1,749 outfits · 720 makeup recipes         │
                  └───────────────────────────────────────────────────────────────┘
On the Mac, offline: Shopify Global Catalog ─► resources/ (Python: catalog + knowledge base)
                     ─► in-vogue/scripts/export_*.py ─► in-vogue/assets/
```

**Inside the app**

```
main_development.dart ┐                        main_production.dart passes no YouCam key ─► stand-ins
main_production.dart  ┴► bootstrap ─► MainInit.init
   flavor ↔ Firebase check ─► Firebase ─► Hive + SQLite ─► core DI ─► 14 feature DIs
   ─► language + saved setup step (before the first frame) ─► InVogueApp ─► EnsureAccount
InVogueApp (MaterialApp.router, Paper theme only) ─► go_router (redirect: setup ⇄ tabs)
   ├─ /setup ► /photo ► /picks ► /sign-in ► /about-you ► /widget        (nested, so Back works)
   └─ tab shell (indexed stack; HomeBloc above the tabs)
        ├─ /home      ─► Shop, Your picks (over the tabs)
        ├─ /makeup    ─► picture viewer   (built on first visit, follows Home's day)
        └─ /settings
features/<name>/  presentation (BLoC, screens) ─► domain (pure Dart) ◄─ data (Firebase, Hive, dio, assets)
                  di/init.dart registers it all in GetIt
```

**Setup**

```
Welcome ─► Your photo ─► Weather + picks ─► Sign in ─────────────► About you ─► Add widget ─► Home
location   body photo    hearts             Apple | Google          name, face    stand-in
                                            restore ─► save         photo
├──────────── nothing leaves the phone ─────┤├──── account in Firebase; YouCam allowed from here ────┤
The step is saved in Hive; the app reopens on it with the earlier screens beneath for Back.
```

**A day's outfit**

```
HomeBloc ─► FollowDay(day on screen), then FollowDay(other day)   (one claim at a time per phone)
FollowDay watches users/{uid}/days/{date}_{occasion} (cache first):
  no record ─► ChooseOutfit ─► transaction: day = making(this phone) + suggestion recorded
  making, this phone, stopped ─► resume (Hive job, same photo, < 2 h)
  making, other phone ─► show its progress; unchanged 10 min ─► take over, same outfit
  ready ─► show the picture (phone copy, else Storage)      failed ─► reason + Try again (same outfit)
MakeOutfit, per piece (bottom ─► top ─► outer | dress ─► outer):
  write progress (stop if another phone took the day) ─► cloth-v4 (poll 5 s, ≤ 4 min)
  last piece ─► download ─► phone + Storage ─► ready
  YouCam refused ─► failed for every phone      network/server error ─► stays making, resumes later
```

**A makeup look**

```
MakeupBloc starts when: face photo kept ∧ the outfit has no look ∧ none being made ∧ last try didn't fail
MakeLook: face ─► before.png (upright, ≤ 1024 px)
  colours ─► colorProfiles/{sha256(face)}, else skin-tone-analysis (20 units, once per photo)
  SkinRules ─► shade + contrast (+ concealer, brow, nude-lip colours)
  key occasion|palette|shade|contrast|weather ─► recipe: 3–6 steps
  each step: makeup-vto on the previous picture (1 unit; poll 3 s, ≤ 2 min) ─► keep ─► show
  done ─► users/{uid}/makeupLooks/{signature} + pictures in Storage and on the phone
```

**Where data lives**

```
PHONE      <support>/in_vogue/<flavor>/
           Hive preferences_<flavor>: language, default_day, setup_step, location, picks, picks_synced,
                profile_name, photo_body, photo_face, install_id, try_on_jobs, makeup_jobs
           SQLite cache.sqlite (forecasts) · files: photos/ outfits/{uid}/ makeup/{uid}/ downloads/
FIRESTORE  users/{uid} profile · wishlist/ · days/ · suggestions/ · makeupLooks/ · colorProfiles/
STORAGE    users/{uid}/ photos/ · days/ · makeup/
ASSETS     catalog/everlane_women.json · outfits/outfits.json · makeup/recipes.json · fonts · images
```
