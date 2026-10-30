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
class WebsitePackageRepository
    implements PackageRepository, CachedPackageSource {
  final Uri catalogUri;
  final CatalogFetcher _fetch;
  final Future<String?> Function(Uri uri)? readCache;

  /// Null until the first successful load. [refresh] resets it.
  Map<String, SoftwarePackage>? _byId;

  WebsitePackageRepository(
    this.catalogUri, {
    CatalogFetcher? fetch,
    this.readCache,
  }) : _fetch = fetch ?? httpGetCatalog;

  /// The catalog from the on-disk cache, if one exists and still parses. A
  /// corrupt cache counts as no cache; the network load reports real problems.
  @override
  Future<List<SoftwarePackage>?> cachedPackages() async {
    final body = await readCache?.call(catalogUri);
    if (body == null) return null;
    try {
      final packages = parseCatalog(catalogUri, body);
      return (_byId ??= {for (final p in packages) p.id: p}).values.toList();
    } on CatalogUnavailable {
      return null;
    }
  }

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
    final previous = _byId;
    _byId = null;
    try {
      await _loaded();
    } catch (_) {
      _byId = previous;
      rethrow;
    }
    if (previous == null) return;
    // The website knows nothing about local installs: keep each surviving
    // package's lifecycle state and installed version, take everything it
    // publishes (content and releases) from the fresh catalog.
    final fresh = _byId!;
    for (final old in previous.values) {
      final incoming = fresh[old.id];
      if (incoming == null) continue;
      fresh[old.id] = old.copyWith(
        name: incoming.name,
        description: incoming.description,
        iconUrl: incoming.iconUrl,
        latestVersion: incoming.latestVersion,
        latestRelease: incoming.latestRelease,
        olderReleases: incoming.olderReleases,
        availableVersions: incoming.availableVersions,
      );
    }
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
    final releases = _releases(source, entry['releases']);
    final latest = releases.isEmpty
        ? const ReleaseNote(version: '', date: '', highlights: [])
        : releases.first;
    return SoftwarePackage(
      id: _idFromUrl(source, entry['url']),
      name: entry['name'] as String,
      description: _text(entry, 'description'),
      subtitle: '',
      currentVersion: '',
      latestVersion: latest.version,
      iconUrl: iconUrl is String && iconUrl.isNotEmpty ? iconUrl : null,
      status: PackageInstallationStatus.notInstalled,
      latestRelease: latest,
      olderReleases: releases.skip(1).toList(),
      availableVersions: [for (final r in releases) r.version],
    );
  }

  /// Releases are published newest first. Empty until the page has a release.
  static List<ReleaseNote> _releases(Uri source, Object? value) {
    if (value == null) return const [];
    if (value is! List) {
      throw CatalogUnavailable(source, 'Releases must be a list.');
    }
    return [for (final r in value) _toRelease(source, r)];
  }

  static ReleaseNote _toRelease(Uri source, Object? value) {
    if (value is! Map || value['version'] is! String) {
      throw CatalogUnavailable(source, 'Release without a version.');
    }
    final highlights = value['highlights'] ?? const [];
    if (highlights is! List || highlights.any((h) => h is! String)) {
      throw CatalogUnavailable(source, 'Release highlights must be strings.');
    }
    return ReleaseNote(
      version: value['version'] as String,
      date: _text(value, 'date'),
      highlights: [for (final h in highlights) h as String],
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

Future<String> httpGetCatalog(Uri uri) async {
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
