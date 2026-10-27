import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Keyboard shortcuts for the Ubuntu frontend.
/// Labels shown to the user come from `hub_keys` (e.g. `Strg+R` or `Ctrl+R`).
abstract final class AppShortcuts {
  static const settings = SingleActivator(
    LogicalKeyboardKey.comma,
    control: true,
  );
  static const refresh = SingleActivator(
    LogicalKeyboardKey.keyR,
    control: true,
  );
  static const refreshAlt = SingleActivator(LogicalKeyboardKey.f5);
  static const search = SingleActivator(
    LogicalKeyboardKey.keyF,
    control: true,
  );
  static const back = SingleActivator(LogicalKeyboardKey.escape);
}
