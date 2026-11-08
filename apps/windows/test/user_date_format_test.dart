import 'dart:io' show Platform;

import 'package:dynamotivation_software_hub/presentation/user_date_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('leaves text that is not a calendar date unchanged', () {
    expect(formatUserDate(''), '');
    expect(formatUserDate('November 2026'), 'November 2026');
    expect(
      formatUserDate('2026-02-31'),
      Platform.isWindows ? '2026-02-31' : '2026-02-31',
    );
  });

  test('formats a date with the user short date pattern on Windows', () {
    final formatted = formatUserDate('2026-11-06');
    if (!Platform.isWindows) {
      expect(formatted, '2026-11-06');
      return;
    }
    expect(formatted, contains('2026'));
    expect(formatted, anyOf(contains('11'), contains('Nov')));
    expect(formatted, contains('6'));
  });
}
