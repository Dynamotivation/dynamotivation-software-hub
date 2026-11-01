# Accessibility audit — 2026-11-01

Scope: Windows/Fluent, macOS/macos_ui, Ubuntu/Yaru, and shared scrolling at commit `0c9d6df` (settings transition branch). This audit adds documentation and diagnostic probes; it does not remediate the UI findings below.

## Assessment

The applications have an accessibility foundation, but none is ready for an accessibility conformance claim. Windows and Ubuntu have functional Tab traversal through many primary controls; Windows custom list focus needs work. macOS has a substantial keyboard gap in its primary buttons and switches. Settings transitions respect reduced motion, but shared scrolling and other animation do not consistently do so. High-contrast support exists but is incomplete and includes a reproducible macOS color conflict. Minimum-window layouts fail where the existing large-window tests pass.

Use [WCAG 2.2](https://www.w3.org/TR/WCAG22/) as the engineering baseline, interpreted for native software through [WCAG2ICT](https://www.w3.org/TR/wcag2ict/). WCAG2ICT is informative guidance, not a certification. Disabling nonessential interaction animation is an additional project requirement (WCAG 2.3.3 is AAA).

## Method and limits

- Read app composition, theme tokens, custom controls, settings, package lists/details, menus, notifications, shortcuts, and existing accessibility tests across all frontends.
- Inspected the pinned `macos_ui 2.2.2` and `fluent_ui 4.17.0` control implementations; standard-looking Flutter controls cannot be assumed to implement native keyboard behavior.
- Ran diagnostic widget probes with the test catalog at 1280×900 and each app's declared minimum window size, at 100% and 200% text size, with reduced motion enabled. Recorded focus traversal and settings semantics. These are Flutter widget tests on Windows, not execution on native macOS or Ubuntu.
- Calculated selected sRGB contrast pairs from source colors with alpha composition. This is a token spot-check, not an exhaustive pixel/gradient/interaction-state contrast audit.
- Ran a shared-scroll probe for reduced-motion wheel behavior and accessible scroll actions.
- Existing required analysis/test suites were rerun. Passing those tests does not negate the findings: current coverage is mostly smoke testing and the diagnostic probes intentionally capture/report failures instead of asserting conformance.
- Not performed: Narrator/NVDA/VoiceOver/Orca sessions, actual macOS Full Keyboard Access, native preference propagation, live keyboard traversal of every dialog/menu and install state, color-vision simulation, screen magnifier testing, touch/precision-trackpad testing, or long-string/RTL coverage. Those remain acceptance work, not assumed passes.

## Findings, ordered by priority

P1 means blocks an important task or removes essential information for an affected user. P2 means a significant usability/coverage gap. All findings are open.

### A01 — P1 — macOS primary actions and switches are skipped by Tab

**Evidence:** `macos_probe.dart` cycles through refresh, Settings, search, package rows, and More options without reaching Launch/Update. Inside Settings, traversal cycles through Back, the appearance popup, and the page focus node; none of the four switches is reached. `macos_ui 2.2.2` implements `PushButton` with MouseRegion/GestureDetector/Semantics and `MacosSwitch` with gesture/render-object handling, without a keyboard focus/action wrapper. App use sites: [primary buttons](../../apps/macos/lib/presentation/widgets/package_detail_view.dart#L214), [switches](../../apps/macos/lib/presentation/widgets/settings_view.dart#L86). Dialog actions also use PushButton, so dialog keyboard operability needs explicit regression coverage.

**Required fix:** Provide app-level accessible button/switch adapters or an evaluated dependency upgrade with focus, Enter/Space activation, visible focus and semantics. Test Launch, Update, Install, each switch, and dialog Cancel/Uninstall with keyboard alone. Verify on native macOS with Full Keyboard Access.

### A02 — P1 — shared scrolling removes accessibility scroll actions

**Evidence:** [hub_scroll.dart](../../packages/hub_scroll/lib/hub_scroll.dart#L28) applies `NeverScrollableScrollPhysics` everywhere and replaces only pointer-wheel signals. The diagnostic long ListView exposes no `SemanticsAction.scrollDown` despite content extending beyond the viewport. This affects all three UIs and risks keyboard scrolling, touch/trackpad input paths, and screen-reader scrolling. Auto-reveal of keyboard focus also needs verification; do not assume a wheel-only test proves it.

**Required fix:** Preserve standard keyboard and semantic scroll paths while intercepting wheel easing. Add separate tests for screen-reader scroll actions, Page Up/Down, focus reveal, touch/trackpad and scrollbar dragging.

### A03 — P1 — macOS light high-contrast toolbar icons become white on white

**Evidence:** [GlassGroup](../../apps/macos/lib/presentation/widgets/glass_controls.dart#L28) uses a solid white fill in light high contrast. [GlassIconButton](../../apps/macos/lib/presentation/widgets/glass_controls.dart#L112) still chooses white glyphs whenever `onGradient` is true, as on the main package toolbar. Glyph contrast is then **1:1**. The high-contrast focus ring changes color, but the icon does not.

**Required fix:** Resolve foreground and background from the same accessible surface tokens. Assert icon contrast for both high-contrast brightness modes, main/settings toolbars, enabled/hover/focus states.

### A04 — P1 — macOS and Ubuntu settings switches have no accessible names

**Evidence:** macOS exposes four switch nodes with empty labels; Ubuntu exposes three unnamed checked controls at normal text size. The [macOS switch builder](../../apps/macos/lib/presentation/widgets/settings_view.dart#L86) omits `semanticLabel`; [Ubuntu preference rows](../../apps/ubuntu/lib/presentation/widgets/settings_view.dart#L100) place label text and YaruSwitch as separate siblings without semantic association. Windows explicitly supplies `semanticLabel: title`, which is better, though its tree also contains extra unnamed inner nodes that need native-reader review.

**Required fix:** Associate title, description, state and action as one usable control. Verify selector names too: an appearance value such as “System” alone does not explain what is being changed. Test accessible names and changed values, rather than the presence of adjacent Text widgets.

### A05 — P1 — essential layout overflows at supported minimum sizes

Declared minimum sizes come from each app's `main.dart`. Diagnostic results:

| Window | Main, 100% | Main, 200% | Settings, 100% | Settings, 200% |
| --- | --- | --- | --- | --- |
| Windows 560×580 | Multiple overflows | Multiple overflows | No reported overflow | No reported overflow |
| macOS 720×520 | No reported overflow | 484 px bottom overflow | No reported overflow | No reported overflow |
| Ubuntu 640×560 | 49 px right overflow | 885 px bottom overflow | No reported overflow | 76 px right overflow |

At 1280×900, main/settings at 100% and 200% reported no layout exceptions in all three frontends. “No reported overflow” is not proof that nothing is truncated or unreachable.

Windows errors identify the [detail Column](../../apps/windows/lib/presentation/widgets/package_detail_pane.dart#L77) and action-label Rows around lines 207/224. macOS [detail layout](../../apps/macos/lib/presentation/widgets/package_detail_view.dart#L45) and Ubuntu [detail layout](../../apps/ubuntu/lib/presentation/widgets/package_detail_view.dart) reserve substantial non-scrolling header space. Ubuntu's [settings appearance row](../../apps/ubuntu/lib/presentation/widgets/settings_view.dart#L152) places a segmented control beside text in a narrow Row.

**Required fix:** Reflow headers/actions/settings rows, allow the necessary content to scroll, and test the actual supported minimums at 100/150/200% plus long translations. Raising minimum sizes alone is not an adequate response to text scaling.

### A06 — P2 — Windows custom list controls have no painted keyboard focus

**Evidence:** [_PackageTile](../../apps/windows/lib/presentation/widgets/package_sidebar.dart#L345) and the Available disclosure use HoverButton, which supplies keyboard focus/actions, but their builders style only hover/selection. They do not use `states.isFocused` or a FocusBorder. The dependency does not paint a ring for the caller. Tab probes do reach these controls; a reachable control can still have invisible focus.

**Required fix:** Add a visible 3:1 focus treatment independent of selection, preserving fixed row coordinates. Test focus on both selected and unselected rows and the disclosure; expose expanded/selected semantics.

### A07 — P2 — macOS glass buttons suppress their semantic activation action

**Evidence:** [GlassIconButton](../../apps/macos/lib/presentation/widgets/glass_controls.dart#L124) uses `Semantics(button: true, label: ..., excludeSemantics: true)` without an outer `onTap`. The excluded child GestureDetector's tap semantics cannot substitute for an explicit semantic action. Keyboard ActivateIntent is a separate path. `_MenuRow` in the same file correctly provides outer `onTap` and demonstrates the missing piece.

**Required fix:** Expose the enabled semantic activation action on the outer node. Assert that screen-reader activation invokes refresh/settings/More/Back exactly once, and disabled controls expose the correct disabled state.

### A08 — P2 — reduced motion only covers part of the interface

**Evidence:** All new settings transitions skip animation under `disableAnimations`, as do Windows departing-row sizes. However:

- [SmoothScroll](../../packages/hub_scroll/lib/hub_scroll.dart#L47) always animates wheel movement for 140–380 ms. With reduced motion true, the probe reached ~65.8 of 100 pixels after 50 ms instead of scrolling immediately.
- Windows [toast AnimatedSwitcher](../../apps/windows/lib/presentation/pages/software_hub_page.dart#L277) retains 250 ms plus a slide. macOS [status transition](../../apps/macos/lib/presentation/pages/software_hub_page.dart#L503) retains 220 ms plus a slide. Probe output confirms those durations under reduced motion; duration alone is not a measurement of rendered movement, but both source paths lack a reduced-motion branch.
- Windows [refresh rotation](../../apps/windows/lib/presentation/widgets/package_sidebar.dart#L54) and Ubuntu [refresh rotation](../../apps/ubuntu/lib/presentation/widgets/ubuntu_header_bar.dart#L48) repeat/finish turns without checking the preference.

**Required fix:** Make scrolling immediate and remove decorative translation/rotation when motion is disabled. Retain a static refresh/busy indicator and readable status. Cover preference changes during an animation, not only startup.

### A09 — P2 — page-entry/return focus and traversal grouping are unspecified

**Evidence:** Settings open/close handlers mainly flip booleans without explicitly moving/restoring focus ([Windows](../../apps/windows/lib/presentation/pages/software_hub_page.dart#L59), [macOS](../../apps/macos/lib/presentation/pages/software_hub_page.dart#L263), [Ubuntu](../../apps/ubuntu/lib/presentation/pages/software_hub_page.dart#L125)). Crossfade exclusion is good, but is not focus restoration. Probes find an extra page-level autofocus stop and spatial ordering that interleaves sidebar rows with detail actions. macOS Search requests focus on a sidebar hidden during Settings.

**Required fix:** Define entry focus, return focus, logical traversal groups and the behavior of Search while Settings is open. Test Tab and Shift+Tab through complete task flows and restore focus after menus/dialogs. This is a code-level design/coverage gap; native focus loss on every route has not been claimed.

### A10 — P2 — unnamed icon actions and incomplete selected-state semantics

**Evidence:** Windows/Ubuntu search-clear IconButtons have neither tooltip nor explicit accessible name ([Windows](../../apps/windows/lib/presentation/widgets/package_sidebar.dart#L148), [Ubuntu](../../apps/ubuntu/lib/presentation/widgets/package_sidebar.dart#L108)). Windows custom package rows and Ubuntu InkWell rows do not explicitly expose selected state, unlike macOS PackageRow's selected semantics. The macOS design-preview traffic lights have labels and semantic taps but are 12×12 pointer-only controls ([preview controls](../../apps/macos/lib/presentation/widgets/mac_window_controls_preview.dart#L35)); this finding does not apply to native macOS traffic lights.

**Required fix:** Localized names/actions/states, selected/expanded semantics, and adequate hit regions. Audit headers, decorative icons and duplicated package images so the reader gets useful information once.

### A11 — P2 — transient feedback is not consistently accessible or recoverable

**Evidence:** Windows uses a live region but removes toasts, including user errors, after 3 s. macOS status has a live region and 3 s timer (errors use dialogs). Ubuntu banners disappear after 4 s and have no live-region wrapper ([banner](../../apps/ubuntu/lib/presentation/pages/software_hub_page.dart#L266)); the close icon is unlabeled and constrained to 20×20. Visual placement alone does not announce a new message.

**Required fix:** Announce statuses without stealing focus; keep actionable/errors available until dismissed or offer a persistent recovery/history route. Name the dismiss action and enlarge its target. Test repeated messages, reader announcements, and focus retention.

### A12 — P2 — contrast/high-contrast coverage is incomplete

**Good spot-checks:** white on Windows/macOS coral `#E22050` = **4.61:1**; white on header `#CC3C3B` = **4.91:1**; white on Windows dark primary `#D23A40` = **4.75:1**. These pass normal-text minimums. They are not all-state guarantees.

Windows strengthens custom tokens under high contrast; macOS removes glass blur and strengthens some borders; Ubuntu supplies Yaru high-contrast themes. However, Ubuntu [sidebar](../../apps/ubuntu/lib/presentation/widgets/package_sidebar.dart#L76) and [settings cards](../../apps/ubuntu/lib/presentation/widgets/settings_view.dart#L57) still force brand surfaces/borders instead of using the high-contrast theme. Windows high contrast retains brand surfaces and header gradients, rather than proving native user-selected contrast colors are respected. macOS ties its transparency fallback to highContrast but does not independently demonstrate native Reduce Transparency propagation. Flutter/native preference mapping is unverified.

**Required fix:** Test composited text/icons/indicators for all interaction states and native contrast modes; avoid bypassing accessible theme surfaces. Capture actual OS preference propagation separately from synthetic MediaQuery tests.

### A13 — P2 — color independence is partly present, not fully verified

Update availability and install status generally have text/version cues; destructive actions have explicit labels and confirmation dialogs. Those are good foundations. macOS package rows also expose update text and selected semantics. But Windows/Ubuntu selection relies on styling without explicit selected semantics, and focus/selection can become ambiguous in grayscale or high contrast. No protan/deutan/tritan simulation has been performed, so there is no basis to declare color-blind readiness or to invent a need for a separate color-blind theme.

**Required fix:** Keep readable state labels and redundant shape/icon/semantic cues; test grayscale and common color-vision deficiencies, especially focused/selected/hovered distinctions. Fix information loss rather than adding decorative palettes.

### A14 — P2 — current tests overstate the assurance they provide

The macOS test named “Tab reaches toolbar buttons and Enter activates” sends 12 Tabs, never sends Enter, and only checks for an exception. Existing high-contrast tests only check for crashes. Large-text tests cover the large main view, not supported minimum sizes, all settings rows or dialogs. Search tests enter text programmatically without asserting which node has focus. There are no assertions covering native readers, accessible scroll actions, semantic activation of custom controls, color pairs or global reduced motion.

**Required fix:** Replace name-only coverage with concrete focus-target, activation, state, label, geometry, motion and contrast assertions. Keep native assistive-technology testing as a separate acceptance gate.

## Addendum — 2026-11-01 Windows remediation status

Status after the accessibility remediation commits on this branch. The
original findings text above is retained for context.

Closed (Windows):

- A02 (code): shared scrolling no longer strips accessibility actions —
  standard physics are restored and wheel easing moved to the position level;
  semantic scroll actions and touch drag are asserted in `hub_scroll` tests.
  Touch/trackpad and physical device verification remain acceptance work.
- A04 (Windows side): switches expose one named, described, stateful node
  (`AccessibleSwitch`); the unnamed forked nodes are gone (probe reports zero
  unnamed flagged nodes). Caption buttons no longer fork unnamed nodes.
- A05 (Windows): no layout exceptions at 560×580 at 100% and 200% in the
  probe; long-translation coverage is still outstanding.
- A06: list rows paint a visible `FocusBorder` and expose selected semantics.
- A08 (Windows side): toast switcher, spin decorations and wheel easing
  honor reduced motion; probes confirm immediate wheel jumps and zero
  transition durations.
- A09 (Windows): the entry/return contract is pinned by tests — startup and
  Ctrl+F own the search field, forward traversal goes search → rows, Escape
  clears the query without dropping selection, settings return focus goes to
  the control that opened it, and dialog dismissal restores the trigger.
- A10: search clear and overflow controls are named `AccessibleIconButton`s.
- A11 (Windows): toasts are live regions with a dismiss control; errors
  persist until dismissed; repeated identical messages re-announce (keyed
  sequence); covered by tests.
- A12: contrast is now measured, not only spot-checked — composited pairs
  (text/muted/subtle/status across surfaces, both header stops, button
  hover/pressed states, row tints, badges, focus strokes, system palettes)
  are asserted in `windows_contrast_matrix_test.dart` at AA minimums.
- A14 (Windows tests): replaced name-only coverage with focus-target,
  activation, semantics-state, live-region, motion and contrast assertions.

Still open — not remediable by code alone, and the work above does not
substitute for them: real Narrator/NVDA sessions on Windows (roles, states,
utterance quality, no traps), native preference propagation while settings
change mid-session, color-vision simulations, long-translation passes at
minimum sizes, and the macOS/Ubuntu findings A01, A03, A04 (macOS/Ubuntu
side), A07, A12 (macOS/Ubuntu side), and the remaining A13 matrix.

## Acceptance addendum — 2026-11-01 Windows native attempt

**Status: incomplete; no native acceptance claim.** The native pass was
attempted at commit `37f7129` on Windows 11, version 25H2, build
26200.9711 (the Windows registry's legacy ProductName reports Windows 10
Home). Display scaling and text size were not established; 100%, 150%, and
200% were not tested. The registry reports `Win8DpiScaling=0`, which does
not establish the effective scaling on the display.

- Rebuilt the Windows Debug runner successfully with `flutter build windows
  --debug`. The prebuilt executable did not expose a window immediately;
  `flutter run -d windows --debug --no-pub` subsequently exposed a window
  titled “Software Hub”. Startup timing was not measured, so this is not a
  finding about startup failure.
- The desktop automation helper reported **“failed to activate captured
  window”** on both the initial activation and a retry after rediscovering
  the window. No screenshot, keyboard traversal, or UI Automation tree was
  captured. Consequently focus-ring contrast, Tab/Shift+Tab order, control
  activation, Escape and dialog focus restoration remain unverified on screen.
- Narrator is installed (`C:\Windows\System32\Narrator.exe`); it was not
  exercised and no announcements were observed. NVDA availability was not
  established. Inspect.exe is installed in the Windows SDK, but its UIA tree
  was not inspected. No screen reader was used in this attempt.
- Live contrast-theme and animation-preference changes, minimum-window
  reflow at each requested text size, scrolling, the uninstall cancel path,
  and both brand themes remain untested. No OS preferences were changed.
  Color-vision simulation, long translations, and physical input paths also
  remain open as recorded above.

The activation failure is a limitation of this test setup, not evidence of
an application defect or a WCAG failure. No new product defects can be
substantiated from this attempt; the earlier findings and their WCAG context
remain applicable. Repeat the native pass in an interactive desktop session,
including actual Narrator or NVDA utterances and all requested preference and
scaling combinations, before closing the acceptance work.

### Follow-up after desktop unlock

The app was restarted in the unlocked session, and screenshots and the
desktop automation tool's UI Automation tree were obtained. The earlier
activation failure was a locked-session limitation. Observations below are
partial, at the default window size in the dark brand theme; effective
display and text scaling were not measured.

- With Settings open, changing Windows Contrast themes from None to Night
  sky changed the running app to black surfaces and white text and borders.
  Returning the OS setting to None restored the dark brand surface and red
  header without restarting the app. This verifies this one palette and view,
  not every control, palette, or contrast ratio.
- Tab from the Settings back button reached Appearance, then the Autostart
  switch. Screenshots showed a light focus outline on each in dark mode.
  This is a sample, not a complete traversal or measured focus contrast.
- The UI Automation tree presents the four named settings switches as
  **buttons**, and its printed summary does not show their on/off states;
  Appearance appears as nested buttons rather than a combobox. The root
  content is nested under a button whose name combines the application title,
  caption labels, update message, and “Minimize”; separate Maximize and Close
  entries within that content appeared as text. This is a **native semantics
  concern** for WCAG 2.2 SC 4.1.2 (Name, Role, Value), requiring inspection of
  the actual UIA patterns and Narrator/NVDA utterances before determining the
  full impact. The tool's abbreviated tree alone does not prove that a toggle
  pattern or state is absent. The earlier Windows A04/A10 code-level closures
  do not establish native-reader acceptance.
- Narrator was not exercised; no speech or activation announcements were
  observed. Inspect.exe was not used. Full keyboard traversal, both brand
  themes, Escape and uninstall-dialog restoration, reduced-motion propagation,
  minimum-size text scaling, and other acceptance items remain open. The
  production catalog showed only one available package, so an unselected row
  and installed/uninstall state were unavailable in this session.

## Reproducing the diagnostic evidence

The adjacent `*_probe.dart` files are deliberately diagnostic collectors, not passing accessibility regression tests. They print captured layout exceptions and semantics/focus observations; an “All tests passed” runner line only means the collector completed. Read the printed findings.

From each corresponding app directory:

```powershell
flutter test --no-pub ../../audits/2026-11-01/windows_probe.dart
flutter test --no-pub ../../audits/2026-11-01/macos_probe.dart
flutter test --no-pub ../../audits/2026-11-01/ubuntu_probe.dart
```

From `packages/hub_scroll`:

```powershell
flutter test --no-pub ../../audits/2026-11-01/scroll_probe.dart
```

The probes use 22 Tab steps in the main view and 10 in Settings; they sample, rather than prove, complete traversal. All use synthetic reduced motion; contrast/native-reader conclusions require the additional work below.

## Remediation sequence and native acceptance

1. Fix A01–A04: keyboard adapters, accessible scrolling, high-contrast glyphs, and named settings controls.
2. Fix minimum-size reflow and visible focus; establish deterministic focus entry/return and semantic activation.
3. Complete reduced motion, persistent/announced feedback, state semantics, target sizes, and accessible theme usage.
4. Add meaningful regressions and run native keyboard + screen-reader sessions on all three operating systems. Test main/search/package selection/install/update/uninstall confirmation/settings/back/error/retry; include long catalogs and off-screen items.
5. For each OS record light/dark, high contrast/increased contrast, reduced motion, reduced transparency where available, 100/150/200% text, normal/minimum windows, grayscale and color-vision simulations. Check platform menu conventions, target sizes and no keyboard traps.

Until that matrix is completed, describe this as an audited implementation with known gaps, not an accessibility-compliant application.
