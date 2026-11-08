import 'dart:convert';
import 'dart:io';

import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'filters publisher and self, keeps unknown versions, deduplicates views',
    () {
      Map<String, String> row(
        String key,
        String name,
        String version, {
        String publisher = 'Dynamotivation',
      }) => {
        'Key': key,
        'DisplayName': name,
        'DisplayVersion': version,
        'Publisher': publisher,
        'DisplayIcon': r'"D:\Games\game.exe",0',
      };
      final apps = WindowsInstalledApplicationRepository.parse(
        jsonEncode([
          row('a_is1', 'A', '1.2'),
          row('a_is1', 'A', '1.0'),
          row('b_is1', 'Local only', ''),
          row(
            'other',
            'Other publisher',
            '1.0',
            publisher: 'Dynamotivation impostor',
          ),
          row(
            '{6F0B3E52-2C58-4C0B-9F5E-1D7A4B8E9C31}_is1',
            'Renamed Hub',
            '1.0',
          ),
          row('legacy', 'Dynamotivation Software Hub', '1.0'),
          row('empty', '', '1.0'),
        ]),
      );
      expect(apps.map((a) => a.name), ['A', 'Local only']);
      expect(apps.map((a) => a.version), ['1.2', '']);
      expect(apps.first.launchExecutable, r'D:\Games\game.exe');
    },
  );

  test('malformed output and read errors are typed scan failures', () async {
    for (final body in ['', '{}', '[42]']) {
      final repo = WindowsInstalledApplicationRepository(
        read: () async => body,
      );
      await expectLater(
        repo.scan(),
        throwsA(isA<InstalledSoftwareUnavailable>()),
      );
    }
    final repo = WindowsInstalledApplicationRepository(
      read: () async => throw const FileSystemException('denied'),
    );
    await expectLater(
      repo.scan(),
      throwsA(isA<InstalledSoftwareUnavailable>()),
    );
  });

  test(
    'native read executes fixed script and returns a parseable inventory',
    () async {
      final apps = await WindowsInstalledApplicationRepository().scan();
      expect(apps.every((a) => a.name.isNotEmpty && a.id.isNotEmpty), isTrue);
      expect(
        apps.any((a) => a.name.toLowerCase() == 'dynamotivation software hub'),
        isFalse,
      );
    },
    skip: !Platform.isWindows,
  );
}
