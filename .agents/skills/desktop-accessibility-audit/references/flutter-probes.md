# Flutter probes that establish behavior

Adapt examples to the pinned Flutter version and each frontend's composition root. Semantics APIs change; inspect the installed SDK instead of guessing deprecated flags or method names.

## Build the matrix from app constraints

Read each app's native `minimumSize` and use logical test dimensions: set `tester.view.physicalSize` and `devicePixelRatio = 1`. Set platform text scaling/accessibility features or explicit MediaQuery values, ensuring they actually reach the tested widget. Reset every override in teardown. Pump a fresh app/controller per case so focus, scroll, timers and theme changes do not leak across observations.

Use settings and other important states, not only the startup main view. A 1280x900 no-overflow test says nothing about a 640x560 settings row. Exercise 150% as well as 200% when the local policy requires it. Use long catalogs to expose off-screen navigation and scrolling.

## Keyboard evidence

Sending twelve Tabs and checking `takeException() == null` is smoke coverage. A behavioral regression should:

1. Send Tab/Shift+Tab and assert which control owns primary focus (inspect its FocusNode/context and ancestors, or deliberately exposed keys).
2. Activate that focused control using the expected key, and assert the callback or resulting application state, not just that an Actions widget exists.
3. Check the focus indicator independently from reachability. A custom HoverButton/FocusableActionDetector may supply actions without painting focus.
4. Open and dismiss settings, a menu and a confirmation dialog; verify meaningful focus entry/return and no traversal into hidden/outgoing content.
5. Reach an off-screen item and assert visibility/scroll position; verify keyboard scroll commands separately.

For diagnostic inventories, print each focus target and recognizable control/semantic label until traversal cycles; avoid claiming completeness from an arbitrary iteration count. Geometric default traversal can interleave sidebar and detail controls. Do not label it a keyboard trap unless a trap was reproduced.

## Semantics evidence

Enable semantics with `tester.ensureSemantics()` and dispose the handle. Examine the actual semantics node/tree, not just a Semantics widget or nearby Text:

- Assert localized accessible name, role, checked/toggled/selected/expanded and enabled states.
- Activate the node through the semantics action API appropriate to the installed SDK; assert exactly one state change/callback.
- An outer `excludeSemantics: true` may remove a child GestureDetector's semantic tap. An outer role and label do not restore the missing action.
- A row containing Text beside a switch does not guarantee the switch receives that name. Merge or explicit label strategies must still preserve value and action.
- Empty inner nodes are evidence to inspect, not automatically multiple user-facing controls: inspect merge boundaries and verify with the native reader before declaring duplicate announcements.
- Verify live regions for newly inserted messages, readable error persistence, and no unintended focus stealing.

For scrolling, traverse the semantics tree and count `SemanticsAction.scrollDown` on a long scrollable. Zero actions with content outside the viewport is a finding requiring investigation. `NeverScrollableScrollPhysics` used to replace wheel behavior is a specific regression risk for semantic/touch/keyboard scrolling.

## Timing and reduced motion

First pump the rebuild that starts the animation, then advance time. A single one-second pump can start an AnimatedSwitcher at that late frame rather than finish it. Use `pumpAndSettle` for bounded page changes, but avoid it while an indeterminate spinner repeats or timers/streams prevent settling. Use deterministic frame advances for in-flight animation assertions.

Set `disableAnimations` and observe actual movement/progress or the final state after a frame; inspecting a duration alone is only supporting source/runtime evidence. A nonzero configured duration can be shortened by framework behavior. An explicit `AnimationController.repeat` can continue despite nominal accessibility support.

For wheel smoothing, send a `PointerScrollEvent`, pump a frame and a short interval, and inspect offset versus the intended destination. Under reduced motion, confirm that the viewport moves without a tween. Also verify semantic scroll, keyboard commands, touch/trackpad where available, and scrollbar dragging. Do not disable all user scrolling merely to prevent duplicate wheel handling.

## Diagnostic collectors versus regressions

A collector may call `takeException()` to record multiple layout cases without aborting the inventory. It must print/store the captured exceptions and clearly state that “All tests passed” only means collection finished. Do not add such collectors to CI as proof that accessibility passes.

A regression for a remediated issue must assert its invariant: no layout exceptions at the required size/text state, correct focused node, successful activation, named/stateful semantics, working scroll action, or motion skipped. Avoid snapshots that merely mirror implementation structure.

## Native acceptance boundary

Flutter widget tests do not exercise platform accessibility bridges, native menu keyboard ownership, actual OS Full Keyboard Access, or OS preference propagation. Complete native task flows using Narrator/NVDA, VoiceOver and Orca on their own operating systems before describing those paths as verified. Record unavailability honestly rather than treating a Windows design preview as a native test.
