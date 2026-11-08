import 'dart:async';
import 'dart:io';

import 'package:dynamotivation_software_hub/platform/single_instance.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('window requests (any platform)', () {
    test('reach the running instance once', () async {
      final first = SingleInstance.withoutMutex(dir);
      final shown = Completer<void>();
      var calls = 0;
      first.listen(() {
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

    test('made before listening are not lost', () async {
      await SingleInstance.requestShow(dir);

      final first = SingleInstance.withoutMutex(dir);
      final shown = Completer<void>();
      first.listen(shown.complete);

      await shown.future.timeout(const Duration(seconds: 5));
      await first.release();
    });
  });

  // The mutex is a Windows call, and the Hub is a Windows app.
  group('one instance per name (Windows)', () {
    final windowsOnly = Platform.isWindows ? false : 'needs Windows';

    test('a second launch is refused and asks for the window', () async {
      final first = await SingleInstance.acquire(dir, name: 'test-a');
      expect(first, isNotNull);

      expect(await SingleInstance.acquire(dir, name: 'test-a'), isNull);
      expect(File('${dir.path}/test-a.show').existsSync(), isTrue);
    }, skip: windowsOnly);

    test('a request left by a dead process is dropped on start', () async {
      await SingleInstance.requestShow(dir, name: 'test-b');

      final first = await SingleInstance.acquire(dir, name: 'test-b');
      var calls = 0;
      first!.listen(() => calls++);
      await Future<void>.delayed(const Duration(milliseconds: 300));

      expect(calls, 0);
      await first.release();
    }, skip: windowsOnly);

    test('different names do not share a lock', () async {
      expect(await SingleInstance.acquire(dir, name: 'test-c'), isNotNull);
      expect(await SingleInstance.acquire(dir, name: 'test-d'), isNotNull);
    }, skip: windowsOnly);
  });
}
