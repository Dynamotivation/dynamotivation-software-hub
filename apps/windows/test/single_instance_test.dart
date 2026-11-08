import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dynamotivation_software_hub/platform/single_instance.dart';

void main() {
  late Directory dir;

  setUp(() {
    // Under the ignored tool folder, not the OS temp directory.
    dir = Directory(
      '${Directory.current.path}/.dart_tool/single_instance_test',
    );
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
  });

  tearDown(() {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });

  test('a request for the window reaches the running instance once', () async {
    final first = await SingleInstance.acquire(dir);
    expect(first, isNotNull);
    final shown = Completer<void>();
    var calls = 0;
    first!.listen(() {
      calls++;
      if (!shown.isCompleted) shown.complete();
    });

    await SingleInstance.requestShow(dir);
    await shown.future.timeout(const Duration(seconds: 5));
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(calls, 1);
    expect(File('${dir.path}/instance.show').existsSync(), isFalse);
    await first.release();
  });

  test('a request made before listening is not lost', () async {
    final first = await SingleInstance.acquire(dir);
    await SingleInstance.requestShow(dir);

    final shown = Completer<void>();
    first!.listen(shown.complete);

    await shown.future.timeout(const Duration(seconds: 5));
    await first.release();
  });

  test('a request left by a dead process is dropped on start', () async {
    await SingleInstance.requestShow(dir);

    final first = await SingleInstance.acquire(dir);
    var calls = 0;
    first!.listen(() => calls++);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    expect(calls, 0);
    await first.release();
  });

  // File locks conflict between handles of one process on Windows only (on
  // Linux they are per process), and the Hub is a Windows app.
  test(
    'a second launch is refused while the first runs, and may start after',
    () async {
      final first = await SingleInstance.acquire(dir);
      expect(first, isNotNull);

      expect(await SingleInstance.acquire(dir), isNull);
      expect(File('${dir.path}/instance.show').existsSync(), isTrue);

      await first!.release();
      final again = await SingleInstance.acquire(dir);
      expect(again, isNotNull);
      await again!.release();
    },
    skip: Platform.isWindows ? false : 'file locks are per process off Windows',
  );

  test('different names do not share a lock', () async {
    final installed = await SingleInstance.acquire(dir, name: 'instance');
    final dev = await SingleInstance.acquire(dir, name: 'instance-dev');
    expect(installed, isNotNull);
    expect(dev, isNotNull);
    await installed!.release();
    await dev!.release();
  });
}
