import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

final _catalogUri = Uri.parse('https://dynamotivation.com/v1/catalog.json/');
const _historyUrl = 'https://dynamotivation.com/v1/software/aoa/releases.json/';

const _catalog =
    '''
{"software": [
  {"name": "AOA", "url": "https://dynamotivation.com/portfolio/software/aoa/",
   "release_count": 3, "releases_url": "$_historyUrl",
   "releases": [{"version": "1.2.3", "date": "2026-11-01", "highlights": []}]},
  {"name": "Other", "url": "https://dynamotivation.com/portfolio/software/other/"}
]}
''';

const _history = '''
{"releases": [
  {"version": "1.2.3", "highlights": []},
  {"version": "1.2.2", "highlights": ["Old"]},
  {"version": "1.2.1", "highlights": []}
]}
''';

HubController _controller(CatalogFetcher fetch) => HubController(
  HubUseCases(
    WebsitePackageRepository(_catalogUri, fetch: fetch),
    InMemorySettingsRepository(),
  ),
);

void main() {
  test('opening the details view fetches the older releases once', () async {
    var historyFetches = 0;
    final c = _controller((uri) async {
      if (uri == _catalogUri) return _catalog;
      historyFetches++;
      return _history;
    });
    await c.load();

    // The catalog was slim; the selected package's history loads on its own.
    expect(c.selected!.id, 'aoa');
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.selected!.olderReleases.map((r) => r.version), ['1.2.2', '1.2.1']);
    expect(c.isLoadingHistory('aoa'), isFalse);
    expect(historyFetches, 1);

    c.select(c.packages.last);
    c.select(c.packages.first);
    await Future<void>.delayed(Duration.zero);
    expect(historyFetches, 1);
  });

  test('a failed fetch is kept for the view and a retry recovers', () async {
    var fail = true;
    final c = _controller((uri) async {
      if (uri == _catalogUri) return _catalog;
      if (fail) throw CatalogUnavailable(uri, 'HTTP 503');
      return _history;
    });
    await c.load();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(c.historyError('aoa'), isA<CatalogUnavailable>());
    expect(c.selected!.hasUnloadedHistory, isTrue);

    fail = false;
    c.loadSelectedHistory();
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(c.historyError('aoa'), isNull);
    expect(c.selected!.olderReleases, hasLength(2));
  });
}
