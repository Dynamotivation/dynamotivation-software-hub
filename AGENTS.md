# AGENTS.md

Single source of truth for this repo. Keep it current; there are no README files.

**Dynamotivation Software Hub** is a desktop launcher and toolbox for the software packages from the same author (Dynamotivation) installed on the user's device. It is a Flutter monorepo (Dart workspace, Flutter 3.47.x, SDK `^3.13.7`) with one frontend per OS. Frontends: `apps/windows` (Fluent UI, the shipping app), `apps/macos` (macos_ui, a design preview that also runs on Windows; native window effects on macOS), and `apps/ubuntu` (Yaru design system, fusing official Ubuntu/GNOME HIG with the Dynamotivation brand identity; runs on Linux and Windows preview). Releases are built locally; there is no CI.

## Layout
```
packages/hub_core    pure Dart (no Flutter): domain, application, infrastructure
packages/hub_l10n    ARB strings + generated AppLocalizations, shared by all frontends
packages/hub_keys    shortcut labels named after the active keyboard layout (Strg/Ctrl/⌘)
packages/hub_scroll  eased mouse-wheel scrolling: SmoothScroll + smoothScrollPhysics
apps/windows         Fluent UI frontend; lib/presentation/{controllers,pages,widgets,theme}
apps/macos           macOS-style frontend; lib/presentation/{pages,widgets}
apps/ubuntu          Ubuntu Yaru frontend; lib/presentation/{controllers,pages,widgets,theme}
```
Root `pubspec.yaml` is the Dart workspace; every package and app is a member.

## Dependency and layering rules
- Dependencies point inward. `apps/*` may import `hub_core`, `hub_l10n`, `hub_keys` and `hub_scroll`. Frontends never import each other.
- `hub_core` must not import Flutter. `packages/hub_core/test/architecture_test.dart` enforces this and the domain → application/infrastructure direction.
- `hub_core` layers:
  - **domain**: `SoftwarePackage`, `AppSettings`. No I/O. Aggregates change only through commands (e.g. `SoftwarePackage.update()`), which enforce the lifecycle and throw `PackageStateException`.
  - **application**: `HubUseCases`, repository ports, and the sealed `HubException` hierarchy (`PackageNotFound`, `PackageActionRejected`). The domain's `PackageStateException` is wrapped into `PackageActionRejected` here so it never leaves the use-case boundary.
  - **infrastructure**: port adapters (in-memory repositories) and `sample_catalog.dart`.
- Frontends import only `package:hub_core/hub_core.dart` (the barrel) and call `HubUseCases` only.
- Composition root: each app's `lib/main.dart` constructs the adapters and `HubUseCases`. That is the only place wiring happens.
- Business rules never live in widgets or controllers. Controllers (`ChangeNotifier`) hold presentation state and call use cases.

## Catalog source
- The software catalog is published by the website (`dynamotivation.github.io`, template `templates/catalog/catalog.json`). The format version is in the URL path, not the document: `/v1/catalog.json/`. Local preview: `http://127.0.0.1:1111/v1/catalog.json/`. Production: `https://dynamotivation.com/v1/catalog.json/`, the default of the Windows app. It reads the catalog through `WebsitePackageRepository`, overridable with `--catalog-url=`.
- The document is `{ "software": [ { name, description, url, icon: {url,width,height}, screenshots, platforms: {windows, macos, linux} } ] }`. Only software whose page sets `[extra.hub] exposed = true` is listed. The package id is the last segment of `url` (the page slug).
- Each software page's front matter has `[extra.hub]`: `exposed` (bool) and `targets` (`windows` x86/x64/arm64, `macos` x64/arm64, `linux` x86/x64/arm64). Targets outside that matrix are dropped by the template.

## Errors
- Never swallow errors. Use cases throw typed `HubException`s; the frontend maps them to localized text in its own `lib/presentation/errors.dart` (`describeError(l10n, error)`). Each frontend has its own copy because frontends never import each other.
- User-initiated failures are shown in the UI (InfoBar, toast, or banner). Background probes that fail are reported via `FlutterError.reportError`, not hidden.
- Known gap: the `hubUpdateVersion: '0.2.0'` literal in `apps/windows/lib/presentation/pages/software_hub_page.dart` is hardcoded, not from a source of truth.

## UI rules
- Shortcuts are shown only via `hub_keys` (`withShortcut`), never as hardcoded "Ctrl+X" strings. The key bindings are defined in each app's `lib/presentation/shortcuts.dart`.
- Text colours must keep ≥ 4.5:1 contrast (3:1 for large text and UI boundaries).
- Custom controls must be keyboard focusable with a visible focus ring and carry `Semantics`.
- Colours come from the platform theme / brand tokens, not arbitrary literals in widgets.
- Every scroll view uses `SmoothScroll` with `physics: smoothScrollPhysics` and a controller it owns and disposes (see `hub_scroll`).
- **Brand Lockup & Logo rules**:
  - Exactly one brand lockup/logo per page, situated at the top of the navigation sidebar or title bar. Never duplicate the logo in the detail view banner or header bar.
  - Never wrap the brand logo in artificial rounded rectangles, gray backgrounds, or borders.
  - Brand name ("Dynamotivation") must use standard theme typography and colors matching macOS and Windows (no custom gradients, forced uppercase, or arbitrary accent colors on brand text).
- **No Platform Tags**:
  - Never add platform edition tags/pills (e.g., "Ubuntu", "Windows Edition", "macOS Edition") to the UI. The OS environment already establishes the platform context.
- **No Pill / Badge Clutter**:
  - Do not place decorative pill containers or badges behind software names, versions, or status text. Use clean typography (`Text`) for names, subtitles, and version lines (`v1.0.0 · Installed`), consistent with the Windows and macOS frontends.
- **Sidebar List Row Stability**:
  - Selection must never shift row content horizontally. Icons and text must remain at fixed x-coordinates whether unselected, hovered, or selected. Highlight selection using row background tint and focus borders only.
- **Destructive Actions (Uninstall)**:
  - Destructive actions such as Uninstall must never be exposed as primary or transparent outline buttons in the main banner.
  - They must require two deliberate clicks: placed inside a 3-dot overflow menu (`...` / `more_horiz`), which triggers a modal confirmation dialog (`AlertDialog` / `ContentDialog` / `MacosAlertDialog`) with Cancel and Uninstall buttons.
- **Launch / Update Button Order**:
  - Launch is always the leftmost action button; Update sits to its right, in every frontend. Launch gets the muscle-memory spot, so an accidental double-click can never trigger an update.
  - Keep the existing emphasis hierarchy: Update stays the filled/prominent control (or the Launch button de-emphasized via a secondary style) — position changes, emphasis does not.
- **Settings View Architecture**:
  - Settings is a global standalone full-page view, never an embedded right pane beside a selected package sidebar. When Settings is open, the package sidebar is hidden, and the header provides a back button to return to the software catalog.

## Localization (`hub_l10n`)
- Source strings: `packages/hub_l10n/lib/l10n/app_en.arb`. Give each key an `@key` description and declare placeholders.
- After editing ARB files, run `flutter gen-l10n` in `packages/hub_l10n`. The generated Dart files are committed.
- Use `context.l10n.<key>` in all user-facing text.
- Keep locales in key parity. `packages/hub_l10n/test/l10n_test.dart` checks this across every `app_*.arb`. A new locale needs only an `app_<locale>.arb` file.
- Translation runs through Crowdin (`crowdin.yml`, `base_path: packages/hub_l10n`, maps `app_en.arb` → `app_%two_letters_code%.arb`). Required environment variables are named `CROWDIN_PROJECT_ID` and `CROWDIN_PERSONAL_TOKEN`; never write their values into the repo. Commands: `crowdin upload sources`, `crowdin download`.
- Catalog content (package names, descriptions, release notes) is not in the ARB files.

## Commands
- `flutter pub get` at the repo root resolves the whole workspace.
- Before finishing, `flutter analyze` and `flutter test` must pass in each of: `packages/hub_core`, `packages/hub_l10n`, `packages/hub_keys`, `packages/hub_scroll`, `apps/windows`, `apps/macos`, `apps/ubuntu`.
- Windows app: `cd apps/windows`, then `flutter run -d windows`. Pass `-a --dark`, `-a --light` or `-a --settings` to start in dark mode, light mode or on the Settings page (`args.contains` in `lib/main.dart`). Release build: `flutter build windows`.
- macOS app: `cd apps/macos`, then `flutter run -d windows` for the design preview or `flutter run -d macos` for native window effects.
- Ubuntu app: `cd apps/ubuntu`, then `flutter run -d windows` for the design preview or `flutter run -d linux` on Ubuntu. Pass `-a --dark` or `-a --settings` to start in dark mode or on the Settings view (`args.contains` in `lib/main.dart`). Release build: `flutter build windows` (preview) or `flutter build linux`.
- `dist/` is gitignored local release output. `err.txt`, `out.txt`, `*.log`, `build/` and `.dart_tool/` are also ignored.

## Code style
- `.editorconfig`: LF line endings, UTF-8, 2-space indent, final newline, trim trailing whitespace (except in `*.md`).

## Adding a frontend
A new OS frontend is a new `apps/<os>` workspace member, added to the root `pubspec.yaml`. Platform-specific code (window chrome, tray, installers) stays in that app.

## Open decisions (ask the owner, don't assume)
- Licence.
- How packages are discovered and installed. The catalog is in-memory sample data, and settings are not persisted yet.
- Installer formats, code signing, and app icons for macOS (`.dmg`/`.pkg`) and Ubuntu (`.deb`/`snap`/`flatpak`) frontends.
