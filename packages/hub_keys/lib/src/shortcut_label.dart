import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'keyboard_layout.dart';
import 'modifier_names.dart';

/// Human-readable text for [activator], e.g. `Strg+R` on a German Windows
/// keyboard, `Ctrl+R` elsewhere and `⌘R` on macOS.
///
/// [platform] and [primaryLanguage] exist for tests; by default they come
/// from the running platform and the active keyboard layout.
String shortcutLabel(
  SingleActivator activator, {
  TargetPlatform? platform,
  int? primaryLanguage,
}) {
  final target = platform ?? defaultTargetPlatform;
  final key = _keyName(activator.trigger);

  if (target == TargetPlatform.macOS) {
    // Apple glyphs are layout independent. Order follows the HIG: ⌃⌥⇧⌘.
    return '${activator.control ? '⌃' : ''}${activator.alt ? '⌥' : ''}'
        '${activator.shift ? '⇧' : ''}${activator.meta ? '⌘' : ''}$key';
  }

  final names = ModifierNames.forPrimaryLanguage(
    primaryLanguage ?? activeKeyboardPrimaryLanguage(),
  );
  return [
    if (activator.control) names.ctrl,
    if (activator.alt) names.alt,
    if (activator.shift) names.shift,
    if (activator.meta) names.meta,
    key,
  ].join('+');
}

/// Appends the shortcut to a tooltip/label: `Settings (Strg+,)`.
String withShortcut(String label, SingleActivator activator) =>
    '$label (${shortcutLabel(activator)})';

String _keyName(LogicalKeyboardKey k) {
  if (k == LogicalKeyboardKey.escape) return 'Esc';
  if (k == LogicalKeyboardKey.comma) return ',';
  final label = k.keyLabel;
  return label.isEmpty ? k.debugName ?? '?' : label.toUpperCase();
}

/// Pointer shortcut using the modifier printed on the active keyboard layout.
String controlClickLabel(String click, {int? primaryLanguage}) =>
    '${ModifierNames.forPrimaryLanguage(primaryLanguage ?? activeKeyboardPrimaryLanguage()).ctrl}+$click';
