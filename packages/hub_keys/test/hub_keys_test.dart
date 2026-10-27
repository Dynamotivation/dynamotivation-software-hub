import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_keys/hub_keys.dart';

void main() {
  const ctrlR = SingleActivator(LogicalKeyboardKey.keyR, control: true);
  const ctrlComma = SingleActivator(LogicalKeyboardKey.comma, control: true);
  String win(SingleActivator a, int? lang) =>
      shortcutLabel(a, platform: TargetPlatform.windows, primaryLanguage: lang);

  test('German keyboard layout says Strg', () {
    expect(win(ctrlR, 0x07), 'Strg+R');
    expect(win(ctrlComma, 0x07), 'Strg+,');
  });

  test('English and unknown layouts say Ctrl', () {
    expect(win(ctrlR, 0x09), 'Ctrl+R');
  });

  test('keys without modifiers', () {
    expect(win(const SingleActivator(LogicalKeyboardKey.f5), 0x07), 'F5');
    expect(win(const SingleActivator(LogicalKeyboardKey.escape), 0x07), 'Esc');
  });

  test('Shift names follow the layout', () {
    const a = SingleActivator(
      LogicalKeyboardKey.keyR,
      control: true,
      shift: true,
    );
    expect(win(a, 0x07), 'Strg+Umschalt+R');
    expect(win(a, 0x0C), 'Ctrl+Maj+R');
  });

  test('macOS uses glyphs regardless of layout', () {
    const cmdR = SingleActivator(LogicalKeyboardKey.keyR, meta: true);
    expect(
      shortcutLabel(
        cmdR,
        platform: TargetPlatform.macOS,
        primaryLanguage: 0x07,
      ),
      '⌘R',
    );
  });

  test('live detection returns a primary language id on Windows', () {
    final id = activeKeyboardPrimaryLanguage();
    // ignore: avoid_print
    print('active keyboard primary language: $id');
    if (Platform.isWindows) {
      expect(id, isNotNull);
      expect(id, inInclusiveRange(1, 0x3FF));
    } else {
      expect(id, isNull);
    }
  });
}
