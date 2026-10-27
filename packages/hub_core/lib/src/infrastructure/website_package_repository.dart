import 'dart:convert';
import 'dart:io';

import '../application/errors.dart';
import '../application/package_repository.dart';
import '../domain/software_package.dart';

/// Returns the response body of a GET request, or throws.
typedef CatalogFetcher = Future<String> Function(Uri uri);

/// Reads the catalog that the Dynamotivation website publishes as JSON.
///
/// The version is part of the URL (`/v1/catalog.json/`), not the document. The
/// document holds a `software` array, and the website lists only the entries
/// the hub is exposed to. The page slug (last segment of `url`) is the package
/// id. The website publishes no version or install data, so packages from it
/// carry empty versions and start as [PackageInstallationStatus.notInstalled].
class WebsitePackageRepository implements PackageRepository {
  final Uri catalogUri;
  final CatalogFetcher _fetch;

  /// Null until the first successful load. [refresh] resets it.
  Map<String, SoftwarePackage>? _byId;

  WebsitePackageRepository(this.catalogUri, {CatalogFetcher? fetch})
    : _fetch = fetch ?? _httpGet;

  Future<Map<String, SoftwarePackage>> _loaded() async {
    final cached = _byId;
    if (cached != null) return cached;
    final body = await _fetch(catalogUri);
    final packages = parseCatalog(catalogUri, body);
    return _byId = {for (final p in packages) p.id: p};
  }

  @override
  Future<List<SoftwarePackage>> all() async =>
      (await _loaded()).values.toList();

  @override
  Future<SoftwarePackage?> find(String id) async => (await _loaded())[id];

  /// Local changes (lifecycle commands) live in memory until [refresh].
  @override
  Future<void> save(SoftwarePackage package) async {
    (await _loaded())[package.id] = package;
  }

  @override
  Future<void> refresh() async {
    _byId = null;
    await _loaded();
  }

  /// Parses a catalog document. Throws [CatalogUnavailable] if the document is
  /// not the expected shape.
  static List<SoftwarePackage> parseCatalog(Uri source, String body) {
    final Object? root;
    try {
      root = jsonDecode(body);
    } on FormatException catch (e) {
      throw CatalogUnavailable(source, 'Not valid JSON: ${e.message}');
    }
    if (root is! Map || root['software'] is! List) {
      throw CatalogUnavailable(source, 'Unsupported catalog shape.');
    }
    return [
      for (final entry in root['software'] as List) _toPackage(source, entry),
    ];
  }

  static SoftwarePackage _toPackage(Uri source, Object? entry) {
    if (entry is! Map || entry['name'] is! String) {
      throw CatalogUnavailable(source, 'Software entry without a name.');
    }
    final icon = entry['icon'] is Map ? entry['icon'] as Map : const {};
    final iconUrl = icon['url'];
    return SoftwarePackage(
      id: _idFromUrl(source, entry['url']),
      name: entry['name'] as String,
      description: _text(entry, 'description'),
      subtitle: '',
      currentVersion: '',
      latestVersion: '',
      iconAsset: '',
      iconUrl: iconUrl is String && iconUrl.isNotEmpty ? iconUrl : null,
      status: PackageInstallationStatus.notInstalled,
      latestRelease: const ReleaseNote(version: '', date: '', highlights: []),
      olderReleases: const [],
      availableVersions: const [],
    );
  }

  /// The page slug is the last non-empty path segment of the software page URL.
  static String _idFromUrl(Uri source, Object? url) {
    final segments = url is String
        ? Uri.tryParse(url)?.pathSegments.where((s) => s.isNotEmpty).toList()
        : null;
    if (segments == null || segments.isEmpty) {
      throw CatalogUnavailable(source, 'Software entry without a page url.');
    }
    return segments.last;
  }

  static String _text(Map<dynamic, dynamic> entry, String key) {
    final value = entry[key];
    return value is String ? value : '';
  }
}

Future<String> _httpGet(Uri uri) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw CatalogUnavailable(uri, 'HTTP ${response.statusCode}');
    }
    return await response.transform(utf8.decoder).join();
  } on SocketException catch (e) {
    throw CatalogUnavailable(uri, e.message);
  } on HttpException catch (e) {
    throw CatalogUnavailable(uri, e.message);
  } finally {
    client.close(force: true);
  }
}
