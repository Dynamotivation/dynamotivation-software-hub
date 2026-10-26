import 'dart:io';

import 'package:test/test.dart';

/// Layering: domain <- application <- infrastructure, and no Flutter anywhere.
void main() {
  Iterable<(String, String)> importsOf(String layer) sync* {
    for (final file in Directory('lib/src/$layer').listSync(recursive: true)) {
      if (file is! File || !file.path.endsWith('.dart')) continue;
      for (final line in file.readAsLinesSync()) {
        if (line.startsWith('import ') || line.startsWith('export ')) {
          yield (file.path, line);
        }
      }
    }
  }

  void expectNoImport(String layer, Pattern forbidden) {
    final offenders = importsOf(
      layer,
    ).where((e) => e.$2.contains(forbidden)).map((e) => '${e.$1}: ${e.$2}');
    expect(offenders, isEmpty);
  }

  test('domain depends on nothing else in the core', () {
    expectNoImport('domain', RegExp(r"application/|infrastructure/"));
  });

  test('application does not depend on infrastructure', () {
    expectNoImport('application', 'infrastructure/');
  });

  test('no layer imports Flutter or dart:ui', () {
    for (final layer in ['domain', 'application', 'infrastructure']) {
      expectNoImport(layer, RegExp(r"package:flutter|dart:ui"));
    }
  });
}
