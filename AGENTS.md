# AGENTS.md

Single source of truth for this repo. Keep it current; there are no README files.

**Dynamotivation Software Hub** is a desktop launcher and toolbox for the software packages from the same author (Dynamotivation) installed on the user's device. It is a Flutter monorepo (Dart workspace, Flutter 3.47.x, SDK `^3.13.7`) with one frontend per OS. Frontends: `apps/windows` (Fluent UI, the shipping app), `apps/macos` (macos_ui, a design preview that also runs on Windows; native window effects on macOS), and `apps/ubuntu` (Yaru design system, fusing official Ubuntu/GNOME HIG with the Dynamotivation brand identity; runs on Linux and Windows preview). CI (`.github/workflows/ci.yml`) analyzes and tests every member on Linux and builds the Windows installer; releases can also be built locally.

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
- The hub reads the software catalog the website publishes. The format version is in the URL path, not the document: `/v1/catalog.json/`. All three apps read the production catalog (`https://dynamotivation.com/v1/catalog.json/`) through `WebsitePackageRepository` by default; pass the local preview with `--catalog-url=http://127.0.0.1:1111/v1/catalog.json/`.
- The document is `{ "software": [ { name, description, url, icon: {url,width,height}, screenshots, platforms, release_count, releases_url, releases: [latest] } ] }`. Only software whose page sets `[extra.hub] exposed = true` is listed. The package id is the last segment of `url` (the page slug). Icon URLs are absolute.
- **The catalog carries only the latest release**, so the main list loads fast. `releases` holds exactly that one release: `{version, date, highlights, downloads: [{platform, arch?, runtime?, variant?, url, sha256, size}]}`. `release_count` is how many exist in total and `releases_url` is the software's own history, `/v1/software/<slug>/releases.json/` = `{slug, releases: [...]}` newest first, same release shape. The hub fetches it when the details view opens (`HubUseCases.loadReleaseHistory`, `WebsitePackageRepository.loadReleaseHistory`, controller `loadSelectedHistory`) and shows "Older releases (N)" from `release_count` before it arrives; a failed fetch shows a retry. A catalog that lists every release inline (old shape) still works. `SoftwarePackage.hasUnloadedHistory` tells whether older releases are still to fetch, and `withReleasesOf` keeps already fetched history across catalog refreshes while the newest release is unchanged.
- **Platforms are open data, not a fixed list.** `platform`, `arch` and `runtime` (`yyc`, `butterscotch`, ...) are independent strings; never hardcode a Windows/macOS/Linux enum in the hub. One platform can have several downloads that differ by runtime or `variant`. `platforms` in a catalog entry maps each declared platform id to its architectures.
- Catalog cache: `CatalogCache` (hub_core) keeps the last good catalog response on disk and serves it when the fetch fails with `CatalogUnavailable` (offline start), setting `servedStale`. Location from `cacheDirectory(app)`: `%LOCALAPPDATA%\<app>\Cache` (Windows), `~/Library/Caches/<app>` (macOS), `$XDG_CACHE_HOME` or `~/.cache/<app>` (Linux). Deliberately not the temp directory, which the OS sweeps automatically. All three apps use it. The UI does not yet show that data is stale.
- Opening the catalog is a use case, not UI logic: `HubUseCases.openCatalog` emits `CatalogSnapshot`s. With a cache: (1) the cached catalog at once (`fromCache`); (2) text of known packages replaced, local state kept, packages that left the catalog kept but marked `departing` for `departGrace`; (3) the departed removed; (4) each new package once its icon is stored (`IconStore.prefetch`, success or failure) and each changed icon URL once the new icon is stored; the last snapshot has `isFinal`. Without a cache: the fresh catalog alone. A failure before any snapshot means nothing to show; after one it is a stream error for the controller to report. Frontends only render snapshots: the Windows controller fades `departingIds` and hands a removed selection to its neighbour; macOS and Ubuntu pass `departGrace: Duration.zero` and show no departing state. `onCatalogSynced` fires on the final snapshot. If loading fails with no cache, macOS and Ubuntu abort startup (no error UI there yet).
- Icons: the catalog serves webp only (icons and screenshots); there are no SVG package icons. `IconCache` (hub_core) stores each icon under `<cache>/icons/`, keyed by URL, fetching once; `hub_images` only adapts it to Flutter (`DiskCachedImage`, `HubIcon`, `HubImageScope`) and drops a stored icon that does not decode. Warm and offline starts show icons. A changed icon must be published under a new URL to be picked up. SVG is used only for the Dynamotivation logo (the UI uses the platform icon fonts, so there are no glyph SVGs).
- The hub parses `releases`, `release_count`, `releases_url` and each download. It does not read `platforms` yet and does not install other software yet; `DownloadLink` only carries the data. Only its own update is downloaded and run (see Self-update).

## Background surface (Windows)
- The background implementation lives in `apps/windows/lib/background`: `TraySurface` (system tray icon, `system_tray`), `HubNotifications` (Windows toasts, `local_notifier`), `UpdateWatchService` (the hourly catalog fetch) and `BackgroundService` (close-to-tray behavior, wiring). `main.dart` is the only wiring point; the pure diff detection is `CatalogUpdateWatcher` in `hub_core`.
- When *Keep running in background* is on, closing the window hides it to the tray (the paused engine stops rendering; only the hourly watch keeps ticking) and the tray icon appears; its right-click menu has *Open Software Hub* and *End* (removes the icon and quits the process). Left-clicking the icon, or clicking a toast, opens the window. With the setting off, nothing changes the default exit behavior.
- The update watch runs about once an hour while the app process runs — window open or tray-only treat it the same. It respects *Automatically check for updates* (fetch + announce) and *Show notifications* (display). New catalog entries and newer release versions are announced; catalog removals are not. Its baseline follows every catalog load the window completed (`HubController.onCatalogSynced`), so something the user already saw on screen is never announced again.
- A failed fetch never blocks or stops the schedule: background failures are reported through `FlutterError.reportError`, not shown as in-app errors.
- The tray icons are the branded favicons in `apps/windows/assets` (`tray_icon.ico` light, `tray_icon_dark.ico` dark). Known gap: the light/dark variant is picked at app start; switching live when the OS theme changes is not implemented.

## Windows installer and signing
- Installer filenames are always lowercase with hyphens: `<product-slug>-setup-<version>.exe`, with a matching `.exe.sha256` file, e.g. `dynamotivation-software-hub-setup-0.1.8.exe`. Never use CamelCase or underscores. Keep compilation, verification, uploads, publishing and test fixtures in step.
- Installer technology: **Inno Setup 5.6.1 (Unicode)**, the last release that produces installers running on Windows XP through 11. Inno 6 dropped XP, so do not upgrade. App scripts carry no Pascal code; the same self-update pattern is used by every app (see Self-update).
- `installer-toolkit/` is a git subtree; its scripts are changed in the toolkit's own repo first, then pulled. `software-hub.iss` is this app's script (`AppId`, `AppName`, `AppExeName`, `MinVersion=10.0.10240` because Flutter requires Windows 10) and includes the shared `common.iss`.
- PR CI runs analysis/tests for all eight workspace members and the version-increment check in `ci/check_version.py`. The Windows release version in `apps/windows/pubspec.yaml` must exceed the PR base version; increasing only `+BUILD` does not count. Stable `MAJOR.MINOR.PATCH` versions are used for installer filenames and `vMAJOR.MINOR.PATCH` tags.
- Every main push runs checks, the full signed Windows build on Ubuntu 24.04, then `ci/publish_release.sh`: it tags the exact pushed main commit and publishes the signed setup plus SHA-256 as a GitHub Release. Existing tags are never moved. Releases stay draft until both assets are uploaded. Tag pushes trigger nothing. Manual runs build/check without publishing a release.
- `installer/linux/setup.sh` installs pinned xwin and Wine tooling; `build_windows.py` invokes Flutter's Windows assemble target, runs the engine-matched Windows AOT snapshot compiler through Wine, and compiles the runner/plugins with Clang 19 and the Microsoft SDK/CRT. This is a custom cross-build path; the standard `flutter build windows` command still requires Windows. `package_windows.py` compiles Inno Setup 5.6.1 through Wine. No Windows runner or VM is configured.
- Signing is mandatory. Both `SIGNING_CERT_PFX_BASE64` and `SIGNING_CERT_PASSWORD` must exist, or packaging fails. Every shipped EXE/DLL, setup, temporary setup copy and uninstaller is signed; signature verification failures stop packaging. Inno calls a small Wine PE bridge, which waits for the Linux `osslsigncode` signer and reports its failure status. Credentials are held in temporary files under the ignored build directory, never in compiler arguments or artifacts. The existing self-signed `CN=Dynamotivation` certificate provides integrity and a consistent publisher identity, not public trust or a SmartScreen reputation; replace the two secrets to change certificates.
- The installer wizard languages mirror the app: `[Languages]` in `installer-toolkit/setup/common.iss` must list exactly the `app_*.arb` locales (enforced by `packages/hub_l10n/test/l10n_test.dart`). Add a locale to both together; use Inno's bundled `compiler:Languages\<Name>.isl`, and add German/other translations for any custom strings.
- The wizard has no install-folder page and no language picker: the install path is fixed and the language follows the Windows UI language (`ShowLanguageDialog=no`). `installer/assets/setup-icon.svg` and `full-logo.svg` feed `render_assets.py`, which generates the per-DPI wizard BMPs and identical setup/app ICOs.
- Known gaps: the new Linux cross-build pipeline is undergoing end-to-end verification. Wine 9 crashes while starting the Windows snapshot compiler; the pipeline pins Wine 11.21. Inno 5.6.1 high-DPI rendering and XP execution remain untested.

## Self-update (Windows)
- The Hub reads its own pending update from the catalog it already loads (`hubPackageId`): `evaluateSelfUpdate` (hub_core) compares the catalog's newest release with the running version (`package_info_plus`, build suffix stripped) and picks the download for this platform and architecture.
- The title-bar update pill calls `HubController.updateHub`: `HubUseCases.stageSelfUpdate` downloads the setup into `<cache>/updates` and verifies the catalog's SHA-256 (`SetupInstaller`, `infrastructure/setup_installer.dart`), `installSelfUpdate` starts it detached as a normal wizard (no switches), and the app quits through `quitForUpdate` so no file is locked. Setup's own close-applications page is the fallback and its launch checkbox reopens the Hub. A bottom InfoBar shows progress while staging; `SetupUnavailable` / `SetupLaunchFailed` show as toasts.
- Cleanup: `clearStagedSelfUpdates` runs at every start; the uninstaller removes the app data and cache folders (`[UninstallDelete]`).
- After `ci/publish_release.sh`, `ci/website_release.sh` records the release for the catalog. `ci/check_version.py` requires `release-notes/<version>.md`. The cross-repo release flow, secrets and hosting are in the machine-wide steering files, not here.
- Known gap: the Hub also shows up in its own software list.

## Errors
- Never swallow errors. Use cases throw typed `HubException`s; the frontend maps them to localized text in its own `lib/presentation/errors.dart` (`describeError(l10n, error)`). Each frontend has its own copy because frontends never import each other.
- User-initiated failures are shown in the UI (InfoBar, toast, or banner). Background probes that fail are reported via `FlutterError.reportError`, not hidden.

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
- **Settings motion**: Windows uses a short upward fade for the heading and cards; macOS crossfades panes while resizing the sidebar; Ubuntu uses a whole-page crossfade (GNOME ViewStack style). Respect `MediaQuery.disableAnimationsOf(context)` in every frontend. Outgoing crossfade content must not accept pointer input, keyboard focus, or accessibility navigation.
- **Settings View Architecture**:
  - Settings is a global standalone full-page view, never an embedded right pane beside a selected package sidebar. When Settings is open, the package sidebar is hidden, and the header provides a back button to return to the software catalog.

## Accessibility requirements (all frontends)
- For accessibility audits and targeted accessibility regression work, use the repository skill [desktop-accessibility-audit](.agents/skills/desktop-accessibility-audit/SKILL.md). It documents the evidence/probe workflow and its limits; it does not replace the requirements below.
- Accessibility is a release requirement, not optional polish. Use WCAG 2.2 AA as the baseline, interpreted for desktop software through [WCAG2ICT](https://www.w3.org/TR/wcag2ict/), together with the platform HIG. Also honor reduced motion for nonessential interaction animation (WCAG 2.3.3, an explicit project requirement beyond AA). Brand styling never overrides accessibility.
- **Keyboard**: Every enabled action must be reachable by Tab/Shift+Tab and operable with the platform's expected activation keys. Composite lists/menus must support their conventional arrow-key behavior and Escape. No traps or silent focus stops. Prefer standard controls, but verify dependency behavior rather than assuming it is accessible.
- **Focus**: Show a persistent, clearly visible keyboard focus indicator with at least 3:1 contrast against adjacent colors. Keep traversal logical, keep focused content visible by scrolling it into view, move focus appropriately on page/dialog/menu entry, and restore it to a meaningful control on exit. Hidden, departing, disabled, or outgoing content must not remain interactive or focusable. For modals, contain focus until dismissal and restore it afterward.
- **Semantics**: Every control must expose its localized accessible name, role, current value/state, enabled state, and activation action. Associate settings labels/descriptions with their switch or selector; visually adjacent text is insufficient. Expose selected/expanded states. Icon-only controls need accessible labels and tooltips. Do not use `excludeSemantics` without explicitly restoring the required actions and state. Mark headings and hide decorative/duplicate imagery appropriately.
- **Motion and scrolling**: Respect `MediaQuery.disableAnimationsOf(context)` throughout the app, including wheel smoothing, refresh decoration, toasts, theme/page transitions, and custom animations. Keep progress understandable with a static/text alternative. Do not disable keyboard, touch/trackpad, or accessibility scroll actions to implement mouse-wheel easing. Changes to `hub_scroll` must preserve all input paths.
- **Contrast and color vision**: Normal text (including placeholders and secondary text) must reach 4.5:1; large text 3:1; meaningful icons, control boundaries, and focus indicators 3:1. Measure the actual composited background, including gradients, alpha, hover/pressed/selected states, and light/dark/high-contrast variants. Never convey selection, update availability, errors, success, or enabled state through color alone; use text, shape/iconography, and semantics. Check grayscale and protan/deutan/tritan simulations when changing meaningful color cues.
- **System preferences**: Follow native high contrast/increased contrast and reduced transparency preferences where available. Custom surfaces must participate in accessible themes, rather than overriding them with brand colors. Verify propagation on the actual target OS; a synthetic MediaQuery test is necessary but insufficient.
- **Text and layout**: Honor system text scaling without clamping it. At 100%, 150%, and 200%, all actions and essential content must remain usable at both normal and declared minimum window sizes. Reflow or scroll instead of clipping/overflowing; test long localized strings. Truncated essential text needs an accessible/full-text route.
- **Targets and feedback**: Use at least 24 by 24 logical pixels for custom pointer targets (prefer native platform sizes or larger), without overlapping hit regions. Announce status changes through appropriate live regions without stealing focus; errors and information needed to complete a task must remain available or be recoverable, rather than existing only in a short timer-driven toast. No flashing effects.
- **Verification**: For affected UI, test actual Tab/Shift+Tab focus targets and Enter/Space activation, switch/selector semantics and values, focus restoration, modal/menu dismissal, reduced motion, scrolling, minimum-size text scaling, and contrast pairs. A test that merely sends keys or enables high contrast and asserts no exception is smoke coverage, not accessibility proof. Use meaningful assertions for regression tests.
- Before claiming native accessibility readiness, manually verify Windows with Narrator (and NVDA where available), macOS with VoiceOver and Full Keyboard Access, and Ubuntu with Orca and keyboard-only navigation. Record OS/settings, tested flows, and remaining gaps; do not infer native screen-reader compatibility from widget tests.
- Current support status and caveats: [ACCESSIBILITY.md](ACCESSIBILITY.md). Audit reports and evidence stay local and are not committed. Existing gaps are tracked debt, not permission to introduce new violations. Update ACCESSIBILITY.md when closing them.

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
