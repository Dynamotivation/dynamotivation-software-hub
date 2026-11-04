import 'dart:io';

import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

class FakeCleaner implements DownloadOriginCleaner {
  final calls = <String>[];
  bool fail = false;
  @override
  Future<void> clear(String path) async {
    calls.add(path);
    if (fail) throw StateError('cleanup failed');
  }
}

void main() {
  test('fresh and reused files are verified before cleanup', () async {
    final cleaner = FakeCleaner();
    for (var i = 0; i < 2; i++) {
      await prepareVerifiedSetup(
        'setup.exe',
        verifySha256: (path) async {
          expect(cleaner.calls.length, i);
        },
        originCleaner: cleaner,
      );
    }
    expect(cleaner.calls, ['setup.exe', 'setup.exe']);
  });
  test('verification failure never clears origin', () async {
    final cleaner = FakeCleaner();
    await expectLater(
      prepareVerifiedSetup(
        'setup.exe',
        verifySha256: (_) async => throw StateError('digest mismatch'),
        originCleaner: cleaner,
      ),
      throwsStateError,
    );
    expect(cleaner.calls, isEmpty);
  });
  test('cleanup failure propagates', () async {
    await expectLater(
      prepareVerifiedSetup(
        'setup.exe',
        verifySha256: (_) async {},
        originCleaner: FakeCleaner()..fail = true,
      ),
      throwsStateError,
    );
  });
  test('Windows stream is removed without changing setup bytes', () async {
    final dir = await Directory.current.createTemp('origin-test-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/setup.exe');
    await file.writeAsString('setup bytes');
    final stream = File('${file.path}:Zone.Identifier');
    await stream.writeAsString('[ZoneTransfer]\r\nZoneId=3\r\n');
    expect(await stream.readAsString(), contains('ZoneId=3'));
    const cleaner = WindowsDownloadOriginCleaner();
    await cleaner.clear(file.path);
    expect(await stream.exists(), isFalse);
    expect(await file.readAsString(), 'setup bytes');
    await cleaner.clear(file.path);
    await expectLater(
      cleaner.clear('${dir.path}/missing.exe'),
      throwsA(isA<FileSystemException>()),
    );
  }, skip: !Platform.isWindows);
}
