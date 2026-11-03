import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

SoftwarePackage hubPackage(String version, List<DownloadLink> downloads) =>
    SoftwarePackage(
      id: hubPackageId,
      name: 'Dynamotivation Software Hub',
      description: '',
      subtitle: '',
      currentVersion: '',
      latestVersion: version,
      status: PackageInstallationStatus.notInstalled,
      latestRelease: ReleaseNote(
        version: version,
        date: '2026-11-03',
        highlights: const [],
        downloads: downloads,
      ),
      olderReleases: const [],
      availableVersions: [version],
    );

SoftwarePackage software(String id, String version) => SoftwarePackage(
  id: id,
  name: id,
  description: '',
  subtitle: '',
  currentVersion: '',
  latestVersion: version,
  status: PackageInstallationStatus.notInstalled,
  latestRelease: ReleaseNote(
    version: version,
    date: '2026-11-03',
    highlights: const [],
  ),
  olderReleases: const [],
  availableVersions: [version],
);

DownloadLink windowsSetup({String version = '0.2.0', String? sha256}) =>
    DownloadLink(
      platform: 'windows',
      arch: 'x64',
      url: 'https://example.com/dynamotivation-software-hub-setup-$version.exe',
      sha256: sha256 ?? ('a' * 64),
      size: 10,
    );

/// A [SetupDownload] that always writes [body] into the destination.
SetupDownload serve(List<int> body) => (uri, sink, {onProgress}) async {
  sink.add(body);
  await sink.flush();
  onProgress?.call(body.length, body.length);
  return body.length;
};

/// Wraps [link] into the offer [stage] takes, version from the filename.
SelfUpdateOffer offerOf(DownloadLink link, {String version = '0.2.0'}) =>
    SelfUpdateOffer(hub: hubPackage(version, [link]), setup: link);

void main() {
  late Directory cache;
  setUp(() => cache = Directory.systemTemp.createTempSync('hub_self_update_test'));
  tearDown(() => cache.deleteSync(recursive: true));

  group('version comparison', () {
    test('numeric segments, padded with zeros', () {
      expect(compareVersions('0.1.10', '0.1.11'), isNegative);
      expect(compareVersions('0.2', '0.1.11'), isPositive);
      expect(compareVersions('1.2', '1.2.0'), isZero);
      expect(compareVersions('1.2.3', '1.2.3'), isZero);
      expect(compareVersions('0.1.0', '0.1'), isZero);
    });

    test('suffixes never raise or lower the numeric order', () {
      expect(compareVersions('1.2.3+4', '1.2.3'), isZero);
      expect(compareVersions('0.1.11-pre', '0.1.10'), isPositive);
    });

    test('versionIsOlder', () {
      expect(versionIsOlder('0.1.10', '0.1.11'), isTrue);
      expect(versionIsOlder('0.1.11', '0.1.11'), isFalse);
      expect(versionIsOlder('0.1.12', '0.1.11'), isFalse);
    });
  });

  group('the catalog offer', () {
    test('the hub itself with a newer release for this device', () {
      final offer = evaluateSelfUpdate(
        packages: [
          software('all-out-attack-generator', '1.2.9'),
          hubPackage('0.2.0', [windowsSetup()]),
        ],
        installedVersion: '0.1.11',
        platform: 'windows',
        arch: 'x64',
      );
      expect(offer!.version, '0.2.0');
      expect(offer.setup.arch, 'x64');
    });

    test('none when the running version is current', () {
      expect(
        evaluateSelfUpdate(
          packages: [hubPackage('0.1.11', [windowsSetup(version: '0.1.11')])],
          installedVersion: '0.1.11',
          platform: 'windows',
          arch: 'x64',
        ),
        isNull,
      );
      expect(
        evaluateSelfUpdate(
          packages: [hubPackage('0.2.0', [windowsSetup()])],
          installedVersion: '0.2.0',
          platform: 'windows',
          arch: 'x64',
        ),
        isNull,
      );
    });

    test('none when the catalog does not list the hub', () {
      expect(
        evaluateSelfUpdate(
          packages: [software('all-out-attack-generator', '1.2.9')],
          installedVersion: '0.1.11',
          platform: 'windows',
          arch: 'x64',
        ),
        isNull,
      );
    });

    test('none when no download fits the device', () {
      final other = DownloadLink(
        platform: 'windows',
        arch: 'x86',
        url: 'https://example.com/other.exe',
        sha256: 'b' * 64,
      );
      expect(
        evaluateSelfUpdate(
          packages: [hubPackage('0.2.0', [other])],
          installedVersion: '0.1.11',
          platform: 'windows',
          arch: 'x64',
        ),
        isNull,
      );
    });

    test('an exact architecture beats an arch-less one', () {
      final exact = DownloadLink(
        platform: 'windows',
        arch: 'x64',
        url: 'https://example.com/exact.exe',
        sha256: 'd' * 64,
      );
      final archless = DownloadLink(
        platform: 'windows',
        url: 'https://example.com/any.exe',
        sha256: 'e' * 64,
      );
      final offer = evaluateSelfUpdate(
        packages: [hubPackage('0.2.0', [archless, exact])],
        installedVersion: '0.1.11',
        platform: 'windows',
        arch: 'x64',
      );
      expect(offer!.setup.url, exact.url);
    });

    test('an arch-less download fits a device of unknown architecture', () {
      final archless = DownloadLink(
        platform: 'linux',
        url: 'https://example.com/any.exe',
        sha256: 'c' * 64,
      );
      final offer = evaluateSelfUpdate(
        packages: [hubPackage('0.2.0', [archless])],
        installedVersion: '0.1.11',
        platform: 'linux',
        arch: '',
      );
      expect(offer, isNotNull);
    });
  });

  group('device architecture', () {
    test('windows registry spellings', () {
      expect(
        deviceArchitecture(
          operatingSystem: 'windows',
          environment: {'PROCESSOR_ARCHITECTURE': 'AMD64'},
        ),
        'x64',
      );
      expect(
        deviceArchitecture(
          operatingSystem: 'windows',
          environment: {'PROCESSOR_ARCHITECTURE': 'ARM64'},
        ),
        'arm64',
      );
      expect(
        deviceArchitecture(operatingSystem: 'web', environment: {}),
        '',
      );
    });
  });

  group('staged setup names', () {
    test('filename-safe versions', () {
      expect(stagedSetupName('0.1.11'), 'setup-0.1.11.exe');
      expect(stagedSetupName('0.2.0+7b'), 'setup-0.2.0-7b.exe');
    });
  });

  group('apply script', () {
    test('runs the setup silently, removes it, and reopens only on restart', () {
      const setup = r'C:\Users\A B\Cache\updates\setup-0.2.0.exe';
      const app = r'C:\Users\A B\Programs\hub.exe';
      final restart = applyScript(setup: setup, app: app);
      expect(restart, contains('"$setup" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART'));
      expect(restart, contains('del /f /q "$setup"'));
      expect(restart, contains('start "" "$app"'));
      expect(restart.indexOf('start ""'), greaterThan(restart.indexOf('/VERYSILENT')));

      final onClose = applyScript(setup: setup);
      expect(onClose, isNot(contains('start ""')));
    });
  });

  group('staging', () {
    test('a verified setup staged earlier is reused, not downloaded again', () async {
      final body = [5, 6, 7];
      final link = DownloadLink(
        platform: 'windows',
        arch: 'x64',
        url: 'https://example.com/s.exe',
        sha256: sha256.convert(body).toString(),
        size: body.length,
      );
      var downloads = 0;
      final installer = StagedSetupInstaller(
        cache,
        download: (uri, sink, {onProgress}) {
          downloads++;
          return serve(body)(uri, sink, onProgress: onProgress);
        },
      );
      final first = await installer.stage(offerOf(link));
      final second = await installer.stage(offerOf(link));
      expect(second, first);
      expect(downloads, 1);

      // A staged file that no longer matches is downloaded again.
      File(first).writeAsBytesSync([0]);
      await installer.stage(offerOf(link));
      expect(downloads, 2);
      expect(File(first).readAsBytesSync(), body);
    });

    test('downloading into Cache\\updates, digest and size verified', () async {
      final body = [1, 2, 3, 4];
      final expected = sha256.convert(body).toString();
      final cache = Directory.systemTemp.createTempSync('hub_stage_ok');
      final staged = await StagedSetupInstaller(
        cache,
        download: serve(body),
      ).stage(
        offerOf(
          DownloadLink(
            platform: 'windows',
            arch: 'x64',
            url: 'https://example.com/s.exe',
            sha256: expected,
            size: body.length,
          ),
        ),
      );
      expect(fileNameOf(staged), 'setup-0.2.0.exe');
      expect(staged, contains('updates'));
      expect(File(staged).readAsBytesSync(), body);
      cache.deleteSync(recursive: true);
    });

    test('a wrong digest leaves nothing staged behind', () async {
      final cache = Directory.systemTemp.createTempSync('hub_stage_bad');
      final installer = StagedSetupInstaller(cache, download: serve([1, 2]));
      await expectLater(
        installer.stage(offerOf(DownloadLink(
          platform: 'windows',
          arch: 'x64',
          url: 'https://example.com/s.exe',
          sha256: 'f' * 64,
        ))),
        throwsA(isA<SetupUnavailable>()),
      );
      expect(stagedFiles(cache), isEmpty);
      cache.deleteSync(recursive: true);
    });

    test('a size disagreement with the catalog refuses the download', () async {
      final body = [1, 2, 3];
      final cache = Directory.systemTemp.createTempSync('hub_stage_size');
      final installer = StagedSetupInstaller(cache, download: serve(body));
      await expectLater(
        installer.stage(offerOf(DownloadLink(
          platform: 'windows',
          arch: 'x64',
          url: 'https://example.com/s.exe',
          sha256: 'f' * 64,
          size: 9,
        ))),
        throwsA(isA<SetupUnavailable>()),
      );
      expect(stagedFiles(cache), isEmpty);
      cache.deleteSync(recursive: true);
    });

    test('staging only keeps the newest; the installer drops others', () async {
      final body = [5, 6];
      final cache = Directory.systemTemp.createTempSync('hub_stage_stale');
      final updates = _updatesDir(cache);
      updates.createSync(recursive: true);
      File('${updates.path}/setup-0.1.9.exe').writeAsBytesSync([1]);
      File('${updates.path}/setup-0.2.0.exe.part').writeAsBytesSync([2]);
      File('${updates.path}/setup-0.2.0.exe').writeAsBytesSync([3]);
      final staged = await StagedSetupInstaller(
        cache,
        download: serve(body),
      ).stage(
        offerOf(
          DownloadLink(
            platform: 'windows',
            arch: 'x64',
            url: 'https://example.com/s.exe',
            sha256: sha256.convert(body).toString(),
          ),
        ),
      );
      expect(fileNameOf(staged), 'setup-0.2.0.exe');
      expect(stagedFiles(cache), contains('setup-0.2.0.exe'));
      expect(stagedFiles(cache).difference({'setup-0.2.0.exe'}), isEmpty);
      cache.deleteSync(recursive: true);
    });

    test('a download transport failure comes out as SetupUnavailable', () async {
      final cache = Directory.systemTemp.createTempSync('hub_stage_fail');
      final installer = StagedSetupInstaller(
        cache,
        download: (uri, sink, {onProgress}) => throw StateError('no net'),
      );
      await expectLater(
        installer.stage(offerOf(DownloadLink(
          platform: 'windows',
          arch: 'x64',
          url: 'https://example.com/s.exe',
          sha256: 'f' * 64,
        ))),
        throwsA(isA<SetupUnavailable>()),
      );
      expect(stagedFiles(cache), isEmpty);
      cache.deleteSync(recursive: true);
    });

    test('progress values rise with the content size and end at full', () async {
      final body = [1, 2, 3, 4];
      final cache = Directory.systemTemp.createTempSync('hub_stage_prog');
      final seen = <double>[];
      await StagedSetupInstaller(
        cache,
        download: serve(body),
      ).stage(
        offerOf(
          DownloadLink(
            platform: 'windows',
            arch: 'x64',
            url: 'https://example.com/s.exe',
            sha256: sha256.convert(body).toString(),
            size: body.length,
          ),
        ),
        onProgress: seen.add,
      );
      expect(seen, everyElement(greaterThanOrEqualTo(0.0)));
      expect(seen, everyElement(lessThanOrEqualTo(1.0)));
      expect(seen.last, 1.0);
      cache.deleteSync(recursive: true);
    });

    test('missing or malformed digests never reach the network', () async {
      final cache = Directory.systemTemp.createTempSync('hub_stage_nodigest');
      var called = false;
      final installer = StagedSetupInstaller(
        cache,
        download: (uri, sink, {onProgress}) async {
          called = true;
          return 0;
        },
      );
      await expectLater(
        installer.stage(offerOf(DownloadLink(
          platform: 'windows',
          arch: 'x64',
          url: 'https://example.com/s.exe',
        ))),
        throwsA(isA<SetupUnavailable>()),
      );
      expect(called, isFalse);
      cache.deleteSync(recursive: true);
    });
  });

  group('clearing staged leftovers', () {
    test('keeps one file and removes the unfinished rest', () async {
      final cache = Directory.systemTemp.createTempSync('hub_stage_clear');
      final updates = _updatesDir(cache);
      updates.createSync(recursive: true);
      final keep = File('${updates.path}/setup-0.2.0.exe')
        ..writeAsBytesSync([1]);
      File('${updates.path}/setup-0.1.8.exe').writeAsBytesSync([2]);
      File('${updates.path}/setup-0.3.0.exe.part').writeAsBytesSync([3]);
      File('${updates.path}/notes.txt').writeAsStringSync('unrelated');
      await StagedSetupInstaller(cache).clearStaged(keep: keep.path);
      expect(
        stagedFiles(cache),
        containsAll(['setup-0.2.0.exe', 'notes.txt']),
      );
      expect(stagedFiles(cache).contains('setup-0.1.8.exe'), isFalse);
      expect(stagedFiles(cache).contains('setup-0.3.0.exe.part'), isFalse);
      cache.deleteSync(recursive: true);
    });
  });
}

Directory _updatesDir(Directory cache) => Directory(
  '${cache.path}${Platform.pathSeparator}updates',
);

Set<String> stagedFiles(Directory cache) {
  final dir = _updatesDir(cache);
  if (!dir.existsSync()) return const {};
  return {
    for (final entry in dir.listSync()) if (entry is File) fileNameOf(entry.path),
  };
}
