# AGENTS.md

Single source of truth for this repo. Keep it current; there are no README files.

**Dynamotivation Software Hub** is a desktop launcher and toolbox for the software packages from the same author (Dynamotivation) installed on the user's device. It is a Flutter monorepo (Dart workspace, Flutter 3.47.x, SDK `^3.13.7`) with one frontend per OS. Frontends: `apps/windows` (Fluent UI, the shipping app), `apps/macos` (macos_ui, a design preview that also runs on Windows; native window effects on macOS), and `apps/ubuntu` (Yaru design system, fusing official Ubuntu/GNOME HIG with the Dynamotivation brand identity; runs on Linux and Windows preview). Releases are built locally; there is no CI.

## Layout
```
packages/hub_core    pure Dart (no Flutter): domain, application, infrastructure
packages/hub_l10n    ARB strings + generated AppLocalizations, shared by all frontends
packages/hub_keys    shortcut labels named after the active keyboard layout (Strg/Ctrl/⌘)
packages/hub_scroll  eased mouse-wheel scrolling: SmoothScroll + smoothScrollPhysics
packages/hub_images  Flutter adapter for catalog icons: HubImageScope + HubIcon over hub_core's IconCache
apps/windows         Fluent UI frontend; lib/presentation/{controllers,pages,widgets,theme}
apps/macos           macOS-style frontend; lib/presentation/{pages,widgets}
apps/ubuntu          Ubuntu Yaru frontend; lib/presentation/{controllers,pages,widgets,theme}
```
Root `pubspec.yaml` is the Dart workspace; every package and app is a member.

## Dependency and layering rules
- Dependencies point inward. `apps/*` may import `hub_core`, `hub_l10n`, `hub_keys`, `hub_scroll` and `hub_images`. Frontends never import each other.
- `hub_core` must not import Flutter. `packages/hub_core/test/architecture_test.dart` enforces this and the domain → application/infrastructure direction.
- `hub_core` layers:
  - **domain**: `SoftwarePackage`, `AppSettings`. No I/O. Aggregates change only through commands (e.g. `SoftwarePackage.update()`), which enforce the lifecycle and throw `PackageStateException`.
  - **application**: `HubUseCases` (incl. `openCatalog`, which sequences cache-first loading), repository ports, the `IconStore` port, `CatalogSnapshot`, and the sealed `HubException` hierarchy (`PackageNotFound`, `PackageActionRejected`). The domain's `PackageStateException` is wrapped into `PackageActionRejected` here so it never leaves the use-case boundary.
  - **infrastructure**: port adapters (`WebsitePackageRepository`, `InMemorySettingsRepository`), `CatalogCache`, `IconCache` (icon files on disk), the catalog address (`catalogUriFromArgs`) and the `HubServices.production(args)` factory that wires all of it, including the cache folder (`hubCacheName`). There is no local sample catalog: every frontend reads the website. Test doubles and fixtures (`InMemoryPackageRepository`, `testCatalog()`) live behind `package:hub_core/testing.dart`, used by tests only.
- Frontends import only `package:hub_core/hub_core.dart` (the barrel) and call `HubUseCases` only.
- Composition root: each app's `lib/main.dart` calls `HubServices.production(args)`, gives `useCases` to its controller and `icons` to a `HubImageScope` above the app. That is the only place wiring happens; no cache logic exists in any frontend.
- Business rules never live in widgets or controllers. Controllers (`ChangeNotifier`) hold presentation state and call use cases.

## Catalog source
- The software catalog is published by the website (GitHub repo `Dynamotivation/dynamotivation.com`; the local checkout folder is still named `dynamotivation.github.io`; template `templates/catalog/catalog.json`). The format version is in the URL path, not the document: `/v1/catalog.json/`. All three apps read the production catalog (`https://dynamotivation.com/v1/catalog.json/`) through `WebsitePackageRepository` by default; pass the local preview with `--catalog-url=http://127.0.0.1:1111/v1/catalog.json/`.
- The document is `{ "software": [ { name, description, url, icon: {url,width,height}, screenshots, platforms: {windows, macos, linux}, releases: [{version, date, highlights}] } ] }`. Only software whose page sets `[extra.hub] exposed = true` is listed. The package id is the last segment of `url` (the page slug). Icon URLs are absolute.
- Each software page's front matter has `[extra.hub]`: `exposed` (bool) and `targets`, written as a table: `targets = { windows = ["x64"], macos = [], linux = [] }`. Allowed values are `windows` x86/x64/arm64, `macos` x64/arm64, `linux` x86/x64/arm64. Targets outside that matrix are dropped by the template. `platforms` in the catalog is built from `targets`.
- Releases live in the website repo at `data/releases.json`, keyed by page slug: `{ "<slug>": { "releases": [ { "version": "1.2.0", "date": "2026-10-01", "highlights": ["..."] } ] } }`. Entries are newest first. Versions are `1.2` or `1.2.3` (optional `-pre`/`+build` suffix), dates are `YYYY-MM-DD`, and versions must be unique. The slug must match a file in `content/portfolio/software/`. Run `python scripts/validate_releases.py` in the website repo before building; CI should run it too.
- The software page shows the newest release with its highlights, and older releases under "Past versions". The newest version is also written to the page's JSON-LD `softwareVersion`. A page without releases shows no release section.
- Catalog cache: `CatalogCache` (hub_core) keeps the last good catalog response on disk and serves it when the fetch fails with `CatalogUnavailable` (offline start), setting `servedStale`. Location from `cacheDirectory(app)`: `%LOCALAPPDATA%\<app>\Cache` (Windows), `~/Library/Caches/<app>` (macOS), `$XDG_CACHE_HOME` or `~/.cache/<app>` (Linux). Deliberately not the temp directory, which the OS sweeps automatically. All three apps use it. The UI does not yet show that data is stale.
- Opening the catalog is a use case, not UI logic: `HubUseCases.openCatalog` emits `CatalogSnapshot`s. With a cache: (1) the cached catalog at once (`fromCache`); (2) text of known packages replaced, local state kept, packages that left the catalog kept but marked `departing` for `departGrace`; (3) the departed removed; (4) each new package once its icon is stored (`IconStore.prefetch`, success or failure) and each changed icon URL once the new icon is stored; the last snapshot has `isFinal`. Without a cache: the fresh catalog alone. A failure before any snapshot means nothing to show; after one it is a stream error for the controller to report. Frontends only render snapshots: the Windows controller fades `departingIds` and hands a removed selection to its neighbour; macOS and Ubuntu pass `departGrace: Duration.zero` and show no departing state. `onCatalogSynced` fires on the final snapshot. If loading fails with no cache, macOS and Ubuntu abort startup (no error UI there yet).
- Icons: the catalog serves webp only (icons and screenshots); there are no SVG package icons. `IconCache` (hub_core) stores each icon under `<cache>/icons/`, keyed by URL, fetching once; `hub_images` only adapts it to Flutter (`DiskCachedImage`, `HubIcon`, `HubImageScope`) and drops a stored icon that does not decode. Warm and offline starts show icons. A changed icon must be published under a new URL to be picked up. SVG is used only for the Dynamotivation logo and UI glyph assets.
- The hub app parses `releases` (`WebsitePackageRepository`). It does not yet read `platforms`.

## Background surface (Windows)
- The background implementation lives in `apps/windows/lib/background`: `TraySurface` (system tray icon, `system_tray`), `HubNotifications` (Windows toasts, `local_notifier`), `UpdateWatchService` (the hourly catalog fetch) and `BackgroundService` (close-to-tray behavior, wiring). `main.dart` is the only wiring point; the pure diff detection is `CatalogUpdateWatcher` in `hub_core`.
- When *Keep running in background* is on, closing the window hides it to the tray (the paused engine stops rendering; only the hourly watch keeps ticking) and the tray icon appears; its right-click menu has *Open Software Hub* and *End* (removes the icon and quits the process). Left-clicking the icon, or clicking a toast, opens the window. With the setting off, nothing changes the default exit behavior.
- The update watch runs about once an hour while the app process runs — window open or tray-only treat it the same. It respects *Automatically check for updates* (fetch + announce) and *Show notifications* (display). New catalog entries and newer release versions are announced; catalog removals are not. Its baseline follows every catalog load the window completed (`HubController.onCatalogSynced`), so something the user already saw on screen is never announced again.
- A failed fetch never blocks or stops the schedule: background failures are reported through `FlutterError.reportError`, not shown as in-app errors.
- The tray icons are the website's branded favicons, copied from the website repo's `public/favicon/favicon.ico` (light) and `favicon-dark.ico` (dark). Known gap: the light/dark variant is picked at app start; switching live when the OS theme changes is not implemented.

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
- **Windows rendering notes**:
  - Build the Fluent themes once (`_DynamotivationAppState` holds them). A fresh `FluentThemeData` per rebuild makes `FluentApp` animate between equal themes and flashes filled buttons square-cornered; `test/button_shape_test.dart` guards this.
  - The refresh icon is the painted `SpinnableRefreshIcon` in `package_sidebar.dart`, not a font glyph or SVG: the glyph's detached arrowhead swings outside the ring while spinning. `test/refresh_icon_test.dart` checks it never crops.
  - Bitmap icons use `FilterQuality.high` (`package_image.dart`). The title-bar logo is `assets/dynamotivation-logo-dark-192.png`, a 192 px render of `dynamotivation-logo-dark.svg` that is downscaled for smoother edges. Regenerate it when the SVG changes.
  - Text is Impeller's grayscale anti-aliasing. Flutter has no ClearType path (flutter/flutter#63043) and release builds cannot select Skia. A per-channel fake was tried and rejected as ugly.
  - `WebsitePackageRepository.refresh()` keeps each known package's install status and installed version and takes everything the website publishes from the new catalog.
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
- How packages are installed and detected on the device. Packages from the website start as not installed and install state is in memory only; settings are not persisted yet.
- Installer formats, code signing, and app icons for macOS (`.dmg`/`.pkg`) and Ubuntu (`.deb`/`snap`/`flatpak`) frontends.
