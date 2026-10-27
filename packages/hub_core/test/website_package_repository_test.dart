import 'package:hub_core/hub_core.dart';
import 'package:test/test.dart';

const _catalog = '''
{
  "software": [
    {
      "name": "Germemz",
      "description": "A test entry.",
      "url": "https://dynamotivation.com/portfolio/software/germemz/",
      "icon": {
        "url": "https://dynamotivation.com/images/germemz.avif",
        "width": 512,
        "height": 512
      },
      "screenshots": [],
      "platforms": {"windows": ["x64"], "macos": [], "linux": []}
    }
  ]
}
''';

final _source = Uri.parse('http://127.0.0.1:1111/v1/catalog.json/');

void main() {
  group('WebsitePackageRepository', () {
    test('maps a catalog entry onto SoftwarePackage', () async {
      final repo = WebsitePackageRepository(
        _source,
        fetch: (_) async => _catalog,
      );
      final packages = await repo.all();

      expect(packages, hasLength(1));
      final p = packages.single;
      expect(p.id, 'germemz');
      expect(p.name, 'Germemz');
      expect(p.description, 'A test entry.');
      expect(p.iconUrl, 'https://dynamotivation.com/images/germemz.avif');
      expect(p.status, PackageInstallationStatus.notInstalled);
    });

    test('takes the id from the last segment of the page url', () {
      final packages = WebsitePackageRepository.parseCatalog(
        _source,
        '{"software": [{"name": "A", "url": "https://x.test/portfolio/software/a-b/"}]}',
      );
      expect(packages.single.id, 'a-b');
    });

    test('fetches once and serves later reads from memory', () async {
      var calls = 0;
      final repo = WebsitePackageRepository(
        _source,
        fetch: (_) async {
          calls++;
          return _catalog;
        },
      );
      await repo.all();
      await repo.find('germemz');
      expect(calls, 1);
      await repo.refresh();
      expect(calls, 2);
    });

    test('keeps lifecycle changes until refresh', () async {
      final repo = WebsitePackageRepository(
        _source,
        fetch: (_) async => _catalog,
      );
      final installed = (await repo.find('germemz'))!.install();
      await repo.save(installed);
      expect((await repo.find('germemz'))!.isInstalled, isTrue);
    });

    test('reports a non-JSON body as CatalogUnavailable', () {
      expect(
        () => WebsitePackageRepository.parseCatalog(_source, '<html>'),
        throwsA(isA<CatalogUnavailable>()),
      );
    });

    test('reports a document without a software list as CatalogUnavailable', () {
      expect(
        () => WebsitePackageRepository.parseCatalog(
          _source,
          '{"software": 1}',
        ),
        throwsA(isA<CatalogUnavailable>()),
      );
    });

    test('propagates fetch failures unchanged', () {
      final repo = WebsitePackageRepository(
        _source,
        fetch: (uri) async =>
            throw CatalogUnavailable(uri, 'Connection refused'),
      );
      expect(repo.all(), throwsA(isA<CatalogUnavailable>()));
    });
  });
}
