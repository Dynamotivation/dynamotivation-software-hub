import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> _keys(String locale) {
  final json = jsonDecode(
    File('lib/l10n/app_$locale.arb').readAsStringSync(),
  ) as Map<String, dynamic>;
  return json.keys.where((k) => !k.startsWith('@')).toSet();
}

void main() {
  test(
    'every translation defines exactly the keys of the English template',
    () {
      final template = _keys('en');
      final l10nDir = Directory('lib/l10n');
      final locales = l10nDir
          .listSync()
          .map((e) => e.uri.pathSegments.last)
          .where((n) => RegExp(r'^app_\w+\.arb$').hasMatch(n))
          .map((n) => n.substring(4, n.length - 4));
      for (final locale in locales) {
        expect(_keys(locale), template, reason: 'app_$locale.arb differs');
      }
    },
  );

  test('the Windows installer offers exactly the app locales', () {
    final appLocales = Directory('lib/l10n')
        .listSync()
        .map((e) => e.uri.pathSegments.last)
        .where((n) => RegExp(r'^app_\w+\.arb$').hasMatch(n))
        .map((n) => n.substring(4, n.length - 4))
        .toSet();
    final iss = File('../../installer/common.iss').readAsStringSync();
    final installerLocales = RegExp(
      r'^Name: "(\w+)"; MessagesFile:',
      multiLine: true,
    ).allMatches(iss).map((m) => m.group(1)!).toSet();
    expect(
      installerLocales,
      appLocales,
      reason: 'installer/common.iss [Languages] must match app_*.arb',
    );
  });
}
