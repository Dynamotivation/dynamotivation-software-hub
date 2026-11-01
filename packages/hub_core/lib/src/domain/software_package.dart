/// Thrown when a lifecycle command is not allowed in the current state.
class PackageStateException implements Exception {
  final String packageId;
  final String message;

  const PackageStateException(this.packageId, this.message);

  @override
  String toString() => 'PackageStateException($packageId): $message';
}

enum PackageInstallationStatus {
  notInstalled,
  installed,
  updateAvailable,
  downloading,
}

/// A file a release can be installed from, for one platform and architecture.
class DownloadLink {
  /// Open vocabulary from the website's platform registry, not a fixed enum:
  /// Butterscotch alone adds consoles, BSDs and many CPU architectures.
  final String platform;
  final String arch;

  /// What runs the game: `yyc`, `butterscotch`, ... Empty if unspecified.
  /// The same platform can be served by more than one runtime.
  final String runtime;

  /// A further distinction within platform, arch and runtime (a Butterscotch
  /// backend, a WAD-specific console build). Empty if none.
  final String variant;
  final String url;

  /// Lowercase hex SHA-256 of the file, or empty if the catalog gives none.
  final String sha256;

  /// Size in bytes, 0 if unknown.
  final int size;

  const DownloadLink({
    required this.platform,
    this.arch = '',
    this.runtime = '',
    this.variant = '',
    required this.url,
    this.sha256 = '',
    this.size = 0,
  });
}

class ReleaseNote {
  final String version;
  final String date;
  final List<String> highlights;
  final List<DownloadLink> downloads;

  const ReleaseNote({
    required this.version,
    required this.date,
    required this.highlights,
    this.downloads = const [],
  });
}

class SoftwarePackage {
  final String id;
  final String name;
  final String description;
  final String subtitle;
  final String currentVersion;
  final String latestVersion;

  /// Absolute address of the icon published by the catalog, if any.
  final String? iconUrl;
  final PackageInstallationStatus status;
  final double downloadProgress;
  final ReleaseNote latestRelease;

  /// Releases before [latestRelease]. The catalog lists only the latest one;
  /// the rest arrives through [releaseHistoryUrl] and stays empty until then.
  final List<ReleaseNote> olderReleases;
  final List<String> availableVersions;

  /// How many releases exist in total, as the catalog reports it. Lets a
  /// frontend say "Older releases (4)" before the history has been fetched.
  final int releaseCount;

  /// Absolute address of this software's full release history, if published.
  final String? releaseHistoryUrl;

  const SoftwarePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.subtitle,
    required this.currentVersion,
    required this.latestVersion,
    this.iconUrl,
    required this.status,
    this.downloadProgress = 0.0,
    required this.latestRelease,
    required this.olderReleases,
    required this.availableVersions,
    this.releaseCount = 0,
    this.releaseHistoryUrl,
  });

  /// Number of releases older than [latestRelease], loaded or not.
  int get olderReleaseCount => releaseCount - 1 > olderReleases.length
      ? releaseCount - 1
      : olderReleases.length;

  /// True while the catalog knows of older releases that were not fetched yet.
  bool get hasUnloadedHistory =>
      releaseHistoryUrl != null && olderReleases.length < olderReleaseCount;

  /// This package with the release data of [next] (a fresh catalog entry) and
  /// local state kept. Already fetched history is kept while the newest
  /// release is still the same, because the catalog entry carries none.
  SoftwarePackage withReleasesOf(SoftwarePackage next) {
    final keepHistory =
        next.latestVersion == latestVersion &&
        olderReleases.length > next.olderReleases.length;
    return copyWith(
      latestVersion: next.latestVersion,
      latestRelease: next.latestRelease,
      olderReleases: keepHistory ? olderReleases : next.olderReleases,
      availableVersions: keepHistory
          ? availableVersions
          : next.availableVersions,
      releaseCount: next.releaseCount,
      releaseHistoryUrl: next.releaseHistoryUrl,
    );
  }

  bool get isInstalled =>
      status == PackageInstallationStatus.installed ||
      status == PackageInstallationStatus.updateAvailable;

  bool get hasUpdate => status == PackageInstallationStatus.updateAvailable;

  bool get isDownloading => status == PackageInstallationStatus.downloading;

  /// Lifecycle command: bring an installed package up to [latestVersion].
  SoftwarePackage update() {
    if (!hasUpdate) {
      throw PackageStateException(id, 'No update available.');
    }
    return copyWith(
      currentVersion: latestVersion,
      status: PackageInstallationStatus.installed,
    );
  }

  /// Lifecycle command: install a package that is not on the device yet.
  SoftwarePackage install() {
    if (status != PackageInstallationStatus.notInstalled) {
      throw PackageStateException(id, 'Already installed or in progress.');
    }
    return copyWith(
      currentVersion: latestVersion,
      status: PackageInstallationStatus.installed,
    );
  }

  /// Lifecycle command: remove an installed package from the device.
  SoftwarePackage uninstall() {
    if (!isInstalled) {
      throw PackageStateException(id, 'Not installed.');
    }
    return copyWith(status: PackageInstallationStatus.notInstalled);
  }

  SoftwarePackage copyWith({
    String? id,
    String? name,
    String? description,
    String? subtitle,
    String? currentVersion,
    String? latestVersion,
    String? iconUrl,
    PackageInstallationStatus? status,
    double? downloadProgress,
    ReleaseNote? latestRelease,
    List<ReleaseNote>? olderReleases,
    List<String>? availableVersions,
    int? releaseCount,
    String? releaseHistoryUrl,
  }) {
    return SoftwarePackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subtitle: subtitle ?? this.subtitle,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      iconUrl: iconUrl ?? this.iconUrl,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      latestRelease: latestRelease ?? this.latestRelease,
      olderReleases: olderReleases ?? this.olderReleases,
      availableVersions: availableVersions ?? this.availableVersions,
      releaseCount: releaseCount ?? this.releaseCount,
      releaseHistoryUrl: releaseHistoryUrl ?? this.releaseHistoryUrl,
    );
  }
}
