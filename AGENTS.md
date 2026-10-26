# AGENTS.md

**Dynamotivation Software Hub**: a desktop launcher/toolbox for managing the software packages from the same author (Dynamotivation) that are installed on the user's device. Flutter + fluent_ui, currently Windows only. Releases are built locally; there's no CI.

## Layout
```
apps/flutter/lib/models   package catalog, package and settings models
apps/flutter/lib/theme    Dynamotivation theme and colour tokens (DynTokens)
apps/flutter/lib/widgets  sidebar, detail pane, settings, title bar
apps/flutter/lib/l10n     ARB strings (gen-l10n, Crowdin-compatible)
```

## Rules
- UI colours come from `DynamotivationTheme` / `DynTokens`, not inline literals where a token exists.
- All user-facing text goes through `context.l10n.<key>`; add keys to `app_en.arb` and run `flutter gen-l10n`. Keep other locales in key parity (`test/l10n_test.dart`).
- Show errors in the UI; never swallow them silently.

## Commands (run in `apps/flutter`)
- `flutter run -d windows` runs the app.
- `flutter analyze` and `flutter test` must pass before you finish.
- `flutter build windows` creates the release build.

## Open decisions (ask the owner, don't assume)
- Licence.
- How packages are discovered and installed. No installer adapter exists yet (the catalog is sample data).
- Installer formats, code signing, app icons, macOS/Linux support.
