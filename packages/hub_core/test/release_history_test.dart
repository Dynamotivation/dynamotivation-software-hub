import 'package:hub_core/hub_core.dart';
import 'package:hub_core/testing.dart';
import 'package:test/test.dart';

final _catalogUri = Uri.parse('https://dynamotivation.com/v1/catalog.json/');
const _historyUrl = 'https://dynamotivation.com/v1/software/aoa/releases.json/';

String _catalog({String latest = '1.2.3', int count = 3}) =>
    '''
{"software": [{
  "name": "AOA",
  "url": "https://dynamotivation.com/portfolio/software/aoa/",
  "release_count": $count,
  "releases_url": "$_historyUrl",
  "releases": [{
    "version": "$latest", "date": "2026-11-01", "highlights": ["New"],
    "downloads": [{
      "platform": "windows", "arch": "x86",
      "url": "https://github.com/x/setup-$latest.exe",
      "sha256": "abc", "size": 42
    }]
  }]
}]}
''';

const _history = '''
{"slug": "aoa", "releases": [
  {"version": "1.2.3", "date": "2026-11-01", "highlights": ["New"], "downloads": []},
  {"version": "1.2.2", "date": "2022-04-19", "highlights": ["Old"], "downloads": []},
  {"version": "1.2.1", "date": "2022-04-17", "highlights": [], "downloads": []}
]}
''';

void main() {
  group('slim catalog', () {
    test(
      'parses the latest release, its downloads and the history pointer',
      () async {
        final repo = WebsitePackageRepository(
          _catalogUri,
          fetch: (_) async => _catalog(),
        );
        final p = (await repo.all()).single;

        expect(p.latestVersion, '1.2.3');
        final download = p.latestRelease.downloads.single;
        expect(download.platform, 'windows');
        expect(download.arch, 'x86');
        expect(download.url, 'https://github.com/x/setup-1.2.3.exe');
        expect(download.sha256, 'abc');
        expect(download.size, 42);
        expect(p.olderReleases, isEmpty);
        expect(p.releaseCount, 3);
        expect(p.olderReleaseCount, 2);
        expect(p.releaseHistoryUrl, _historyUrl);
        expect(p.hasUnloadedHistory, isTrue);
      },
    );

    test('a catalog that lists every release inline needs no fetch', () async {
      final repo = WebsitePackageRepository(
        _catalogUri,
        fetch: (_) async =>
            '{"software": [{"name": "A", "url": "https://x.test/a/", "releases": ['
            '{"version": "2.0.0"}, {"version": "1.0.0"}]}]}',
      );
      final p = (await repo.all()).single;
      expect(p.olderReleases.map((r) => r.version), ['1.0.0']);
      expect(p.hasUnloadedHistory, isFalse);
    });

    test('rejects downloads without a url', () {
      expect(
        () => WebsitePackageRepository.parseCatalog(
          _catalogUri,
          '{"software": [{"name": "A", "url": "https://x.test/a/", '
          '"releases": [{"version": "1.0.0", "downloads": [{"arch": "x86"}]}]}]}',
        ),
        throwsA(isA<CatalogUnavailable>()),
      );
    });
  });

  group('loadReleaseHistory', () {
    late List<Uri> fetched;
    late WebsitePackageRepository repo;

    setUp(() {
      fetched = [];
      repo = WebsitePackageRepository(
        _catalogUri,
        fetch: (uri) async {
          fetched.add(uri);
          return uri == _catalogUri ? _catalog() : _history;
        },
      );
    });

    test('fetches the history on demand and keeps the latest out of the older list', () async {
      await repo.all();
      expect(fetched, [_catalogUri]);

      final p = await HubUseCases(
        repo,
        InMemorySettingsRepository(),
      ).loadReleaseHistory('aoa');

      expect(fetched.last, Uri.parse(_historyUrl));
      expect(p.latestVersion, '1.2.3');
      expect(p.olderReleases.map((r) => r.version), ['1.2.2', '1.2.1']);
      expect(p.availableVersions, ['1.2.3', '1.2.2', '1.2.1']);
      expect(p.hasUnloadedHistory, isFalse);
      expect((await repo.find('aoa'))!.olderReleases, hasLength(2));
    });

    test('fetches only once', () async {
      final uc = HubUseCases(repo, InMemorySettingsRepository());
      await uc.loadReleaseHistory('aoa');
      await uc.loadReleaseHistory('aoa');
      expect(fetched.where((u) => u != _catalogUri), hasLength(1));
    });

    test('a failing history fetch surfaces as CatalogUnavailable and can be retried', () async {
      var fail = true;
      final flaky = WebsitePackageRepository(
        _catalogUri,
        fetch: (uri) async {
          if (uri == _catalogUri) return _catalog();
          if (fail) throw CatalogUnavailable(uri, 'HTTP 503');
          return _history;
        },
      );
      final uc = HubUseCases(flaky, InMemorySettingsRepository());
      await expectLater(
        uc.loadReleaseHistory('aoa'),
        throwsA(isA<CatalogUnavailable>()),
      );
      fail = false;
      expect((await uc.loadReleaseHistory('aoa')).olderReleases, hasLength(2));
    });

    test(
      'a refresh with the same newest release keeps the loaded history',
      () async {
        final uc = HubUseCases(repo, InMemorySettingsRepository());
        await uc.loadReleaseHistory('aoa');
        await repo.refresh();
        final p = (await repo.find('aoa'))!;
        expect(p.olderReleases, hasLength(2));
        expect(p.hasUnloadedHistory, isFalse);
      },
    );

    test(
      'a refresh with a new newest release drops the stale history',
      () async {
        var latest = '1.2.3';
        final moving = WebsitePackageRepository(
          _catalogUri,
          fetch: (uri) async => uri == _catalogUri
              ? _catalog(latest: latest, count: latest == '1.2.3' ? 3 : 4)
              : _history,
        );
        final uc = HubUseCases(moving, InMemorySettingsRepository());
        await uc.loadReleaseHistory('aoa');
        latest = '1.2.4';
        await moving.refresh();
        final p = (await moving.find('aoa'))!;
        expect(p.latestVersion, '1.2.4');
        expect(p.hasUnloadedHistory, isTrue);
      },
    );

    test(
      'a repository without a separate history returns the package as is',
      () async {
        final uc = HubUseCases(
          InMemoryPackageRepository(testCatalog()),
          InMemorySettingsRepository(),
        );
        final first = (await uc.listPackages()).first;
        expect((await uc.loadReleaseHistory(first.id)).id, first.id);
      },
    );
  });
}
