# Project instructions

- THINK LOGICALLY ABOUT WHAT YOU ARE DOING (owner rule). Check every step against the product's rules and costs before building it. Example: no YouCam call before sign-up, because anonymous use would spend tokens with no tracking.
- Use the `flutterN` alias, never `flutter`, for Flutter commands. In this environment it is available through `zsh -ic`.
- Read and maintain `../checkpoint.md` as the resumable source of truth for plans, progress, decisions, and verification.
- Use feature-first Clean Architecture, BLoC, GetIt, Hive, SQLite, and test-driven development.
- Keep domain code independent of Flutter, Firebase, and storage implementations. Translate failures in the presentation layer.
- Use `context.translated` for UI localization. English is the default; also support Spanish and Chinese.
- Work on feature branches and make small, meaningful commits. Development is the normal demo flavor.
- Do not add GitHub/Git-hosted workflows or CI/CD setup. Run verification locally; this is an explicit owner instruction.
- Do not run native builds (APK, iOS, simulator, integration tests) unless the owner asks; rely on automated tests. The owner's device runs are the native check (owner instruction, October 16).
- The design system lives in `lib/core/presentation/`; `../design-spec/` is its source of truth. One light theme only.
- Leave `../design-spec/` as is unless the owner explicitly asks otherwise (owner rule). Record newer owner decisions in `../checkpoint.md` instead.
- Keep code comments concise: say what the code is or does, not where it is used.
