# Accessibility

Our target is **WCAG 2.2 AA** for desktop software, using
[WCAG2ICT](https://www.w3.org/TR/wcag2ict/). Full conformance is not yet verified.

## Feature support

Reviewed **2 November 2026**. Applies to the current development build.

- **Verified:** tested with assistive technology on that operating system.
- **Partial:** implemented, but checks remain or problems are known. See
  [Windows caveats](#windows-caveats).
- **Not tested:** native verification has not been completed.

| Feature | Windows | macOS | Linux |
| --- | --- | --- | --- |
| Keyboard navigation | Verified: dark and light, 100% text size, 1006×774 window | Not tested | Not tested |
| Visible keyboard focus | Verified: dark and light, 100% text size, 1006×774 window | Not tested | Not tested |
| Search with a screen reader | Verified: Narrator, NVDA | Not tested | Not tested |
| Settings switch names and state changes | Verified: Narrator, NVDA | Not tested | Not tested |
| Settings descriptions read aloud | Partial (1) | Not tested | Not tested |
| Menu and selector names and roles | Partial (2) | Not tested | Not tested |
| Dialogs and package actions with a screen reader | Partial (3) | Not tested | Not tested |
| High-contrast themes | Partial (4) | Not tested | Not tested |
| Reduced motion | Partial (5) | Not tested | Not tested |
| Larger text at minimum window size | Partial (6) | Not tested | Not tested |

Windows reader checks cover search and all four settings switches, not the whole
app. NVDA 2026.2 was tested with its non-UIAccess launcher. Automated tests support
other checks but do not replace native testing.

## Windows caveats

1. **Settings descriptions:** screen readers announce each switch's name and
   state, but the description text below it may not be read.
2. **Menus and selectors:** the Appearance selector and the overflow menu are
   reachable and operable by keyboard, but readers report a generic button
   role instead of a combobox or menu role. Appearance's value can be read
   without its name.
3. **Dialogs and package actions:** overflow → Uninstall → Cancel works with
   the keyboard and restores focus. Unselected and off-screen package rows
   have not been checked with a reader, because the catalog has only one
   package.
4. **High contrast:** the app follows the Night sky contrast theme live and
   restores the brand theme when it is turned off. Other contrast themes,
   every view, and measured contrast ratios have not been checked.
5. **Reduced motion:** with Windows Animation effects off, one sampled page
   transition looked already finished in the first screenshot. Toasts, switches, the refresh spinner and wheel scrolling have
   not been timed live.
6. **Larger text:** at the minimum window size, 150% and 200% text keep the
   detail view and Settings reachable by scrolling. These were sampled
   screenshots. A full keyboard pass at 150% and 200%, and long translations,
   are still open.

## Known reader limitations

| Windows behavior | What you may hear |
| --- | --- |
| Switch role | “Check box” rather than “switch” |
| Switch state in NVDA | An extra “not selected” on initial focus |
| Settings descriptions | Description text may not be read |
| Menus and selectors | A generic role instead of the expected menu or selector role |

## Report a barrier

[Open an accessibility issue](https://github.com/Dynamotivation/dynamotivation-software-hub/issues/new).
Tell us what you tried and what went wrong. If possible, include your app version,
operating system, and screen reader. Screenshots or speech transcripts are optional.
Please leave out personal information.

[Contributor requirements](AGENTS.md#accessibility-requirements-all-frontends)
