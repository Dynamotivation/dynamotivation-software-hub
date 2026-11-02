---
name: desktop-accessibility-audit
description: Audit desktop UI accessibility using source review, executable keyboard and semantics probes, contrast measurements, and explicit native-test limits. Use for requested accessibility audits or targeted accessibility regression work, especially Flutter frontends; do not turn unrelated UI edits into a full audit.
---

# Desktop accessibility audit

Produce an evidence-backed assessment and reproducible tests. Preserve the requested scope: an audit does not imply permission to redesign the UI, fix every finding, publish changes, or run other agents. Follow the repository's accessibility policy and required checks.

## Establish the evidence boundary

Identify frontends, UI dependencies and pinned versions, native target operating systems, declared minimum window sizes, localization and theme architecture, shared controls, and existing tests. Record the revision and any uncommitted code affecting the audit. Inspect the dependency implementation when a control's behavior matters: a native-looking widget is not proof of keyboard or semantic support.

Use WCAG 2.2 AA as an engineering baseline interpreted through [WCAG2ICT](https://www.w3.org/TR/wcag2ict/); follow any stronger project requirements such as disabling interaction animation. Consult official platform guidance for native conventions. Do not turn informative guidance into a certification claim.

Keep these evidence classes distinct:

- **Source finding:** identify the responsible path and mechanism; distinguish confirmed code behavior from a risk requiring a runtime check.
- **Widget/runtime observation:** record the environment, fixture, window/text/theme/preferences, stimulus, and observed result.
- **Calculated contrast:** identify foreground, effective background, alpha composition, state, and threshold.
- **Native observation:** identify OS, reader/input method, settings, and task flow actually exercised.
- **Unverified:** say what remains untested. Windows-hosted macOS/Ubuntu Flutter probes cannot establish native VoiceOver/Orca behavior or preference propagation.

## Inspect and probe

Read [Flutter probe guidance](references/flutter-probes.md) when testing Flutter. Reuse existing fixtures and mocks; do not require the live catalog or mutate user settings to run widget tests.

Cover the relevant paths across every requested frontend:

- Keyboard: Tab and Shift+Tab targets, Enter/Space activation, conventional arrow-key navigation in composite widgets, Escape, modal/menu focus containment and restoration, page entry/return focus, and focused off-screen content revealing itself.
- Semantics: localized name, role, state/value, enabled state, semantic activation, selected/expanded states, labels associated with controls, headings, decorative/duplicate content, and live status announcements. Adjacent visible text does not necessarily name a switch.
- Motion: page/theme changes, refresh decoration, notices, departing rows, wheel smoothing, and custom controllers. Exercise reduced motion at startup and while running; keep busy status understandable without decorative movement.
- Scrolling: keyboard Page Up/Down, screen-reader scroll actions, focused-child reveal, wheel, scrollbar, touch/trackpad as available. An eased wheel demo does not prove other input paths work.
- Layout: normal and declared minimum window sizes; 100/150/200% text where required; settings, dialogs and long localized strings as well as the main view. Report overflow, clipping and unreachable actions separately.
- Contrast: actual composited colors for text, icons, boundaries and focus across light/dark/high contrast and hover/pressed/selected/disabled states. Test transparency and gradients where content appears, rather than trusting token comments.
- Color independence: confirm that status, errors, selection and availability have redundant readable/shape/semantic cues. Use grayscale and common color-vision simulations when available. Mark simulations unperformed when they were not run; do not infer readiness from a colorful screenshot.
- Targets and feedback: effective hit regions, labels for icon actions, error recovery, announcement behavior and sufficient availability of important messages. A short timed error toast needs a persistent/recoverable alternative.

Select probes that resolve uncertainty instead of generating a fixed number of tests. Do not suppress exceptions merely to obtain a green suite. If a diagnostic collector intentionally captures exceptions, label it as diagnostic and report its observations even when the runner exits successfully. Convert fixed bugs into real regression assertions when remediation is requested.

For color calculations use [scripts/contrast.py](scripts/contrast.py). It accepts CSS `#RRGGBB` or `#RRGGBBAA` (alpha last), not Flutter's `0xAARRGGBB`. For example:

```powershell
py .agents/skills/desktop-accessibility-audit/scripts/contrast.py --foreground '#FFFFFF' --background '#E22050' --threshold 4.5
```

A passing pair is a spot-check, not an all-state contrast pass. For gradients sample the actual relevant background range; include hover overlays and glass layers. The calculator composites in sRGB then computes relative luminance.

## Report and preserve

Lead with task-blocking findings. For each finding include severity rationale, affected frontend/path, reproduction and evidence, user impact, recommended fix, verification needed, and status. Use stable finding IDs so later work can close or qualify them. Include working foundations without treating them as compliance proof.

Persist the report and reusable probes in the repository's established audit location. Keep diagnostic output separate from the normal regression suite. Document exact commands and whether collector success means only successful execution. Do not copy stale findings from an earlier report without reproducing or checking them against the current revision.

If asked to amend agent instructions, add actionable requirements and test gates, not an assertion that the audited UI already satisfies them. Link the report/backlog. Keep unrelated instructions intact.

Run repository-required checks when applicable. Separate their results from accessibility results: a passing smoke suite is compatible with serious audit findings. State native-reader, platform-preference, text/layout, and color-simulation gaps explicitly. Do not claim native accessibility readiness until those acceptance checks were actually completed.
