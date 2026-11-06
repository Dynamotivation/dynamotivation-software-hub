import 'package:dynamotivation_software_hub/presentation/controllers/hub_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hub_core/hub_core.dart';

final _uri = Uri.parse('https://dynamotivation.com/v1/catalog.json/');

String _catalog(String version) => '''
{"software": [
  {"name": "Generator", "url": "https://dynamotivation.com/portfolio/software/generator/",
   "release_count": 1,
   "releases": [{"version": "$version", "date": "2026-11-03", "highlights": []}]}
]}
''';

void main() {
  test('what the background fetch learned is in the window when it reopens',
      () async {
    var served = '1.0.0';
    final useCases = HubUseCases(
      WebsitePackageRepository(_uri, fetch: (uri) async => _catalog(served)),
      InMemorySettingsRepository(),
    );
    final c = HubController(useCases);
    await c.load();
    await c.revalidation;
    expect(c.packages.single.latestVersion, '1.0.0');

    // The hourly watch fetches while the window is hidden ...
    served = '1.1.0';
    await useCases.refreshCatalog();
    expect(c.packages.single.latestVersion, '1.0.0'); // not adopted yet

    // ... and hands the result to the controller.
    var notified = 0;
    c.addListener(() => notified++);
    await c.syncFromSource();
    expect(c.packages.single.latestVersion, '1.1.0');
    expect(notified, greaterThan(0));
    expect(c.selected?.id, 'generator');
  });
}
