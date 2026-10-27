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

class ReleaseNote {
  final String version;
  final String date;
  final List<String> highlights;

  const ReleaseNote({
    required this.version,
    required this.date,
    required this.highlights,
  });
}

class SoftwarePackage {
  final String id;
  final String name;
  final String description;
  final String subtitle;
  final String currentVersion;
  final String latestVersion;
  final String iconAsset;

  /// Absolute address of the icon published by the catalog, if any.
  final String? iconUrl;
  final bool isSvgIcon;
  final PackageInstallationStatus status;
  final double downloadProgress;
  final ReleaseNote latestRelease;
  final List<ReleaseNote> olderReleases;
  final List<String> availableVersions;

  const SoftwarePackage({
    required this.id,
    required this.name,
    required this.description,
    required this.subtitle,
    required this.currentVersion,
    required this.latestVersion,
    required this.iconAsset,
    this.iconUrl,
    this.isSvgIcon = false,
    required this.status,
    this.downloadProgress = 0.0,
    required this.latestRelease,
    required this.olderReleases,
    required this.availableVersions,
  });

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
    String? iconAsset,
    String? iconUrl,
    bool? isSvgIcon,
    PackageInstallationStatus? status,
    double? downloadProgress,
    ReleaseNote? latestRelease,
    List<ReleaseNote>? olderReleases,
    List<String>? availableVersions,
  }) {
    return SoftwarePackage(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subtitle: subtitle ?? this.subtitle,
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      iconAsset: iconAsset ?? this.iconAsset,
      iconUrl: iconUrl ?? this.iconUrl,
      isSvgIcon: isSvgIcon ?? this.isSvgIcon,
      status: status ?? this.status,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      latestRelease: latestRelease ?? this.latestRelease,
      olderReleases: olderReleases ?? this.olderReleases,
      availableVersions: availableVersions ?? this.availableVersions,
    );
  }
}
