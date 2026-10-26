# AGENTS.md

**Dynamotivation Software Hub**: a desktop launcher/toolbox for managing the software packages from the same author (Dynamotivation) that are installed on the user's device. Flutter monorepo (Dart workspace), one frontend per OS, currently Windows only. Releases are built locally; there's no CI.

## Layout
```
packages/hub_core   pure Dart (no Flutter): domain, application, infrastructure
packages/hub_l10n   ARB strings + generated AppLocalizations, shared by all frontends
apps/windows        Fluent UI frontend; lib/presentation/{controllers,pages,widgets,theme}
```

## Rules
- Dependencies point inward: `apps/*` -> `hub_core`, `hub_l10n`; frontends never import each other. `hub_core` must not import Flutter (`packages/hub_core/test/architecture_test.dart` enforces layering).
- domain: aggregates change only through commands (e.g. `SoftwarePackage.update()`) that enforce the lifecycle. application: `HubUseCases` + repository ports, typed `HubException`s. infrastructure: port adapters. Frontends call `HubUseCases` only.
- Business rules never live in widgets or controllers. Controllers (`ChangeNotifier`) hold presentation state and call use cases.
- Never swallow errors; show them in the UI (map `HubException` to localized text).
- A new OS frontend is a new `apps/<os>` workspace member (add it to the root `pubspec.yaml`); platform-specific code (window chrome, tray, installers) stays in that app.
- UI colours come from `DynamotivationTheme` / `DynTokens`. All user-facing text uses `context.l10n.<key>`: add keys to `packages/hub_l10n/lib/l10n/app_en.arb`, run `flutter gen-l10n` there, keep locales in key parity.

## Commands
- `flutter pub get` at the repo root resolves the whole workspace.
- Per package (`packages/hub_core`, `packages/hub_l10n`, `apps/windows`): `flutter analyze` and `flutter test` must pass before you finish.
- `flutter run -d windows` / `flutter build windows` in `apps/windows`.

## Open decisions (ask the owner, don't assume)
- Licence.
- How packages are discovered and installed. The catalog is in-memory sample data and settings are not persisted yet.
- Installer formats, code signing, app icons, macOS/Linux frontends.
