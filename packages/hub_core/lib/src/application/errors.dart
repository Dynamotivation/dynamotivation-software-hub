/// Typed failures of the use cases. Frontends map these to localized text.
sealed class HubException implements Exception {
  const HubException();
}

class PackageNotFound extends HubException {
  final String id;
  const PackageNotFound(this.id);

  @override
  String toString() => 'PackageNotFound($id)';
}

/// A lifecycle command was refused by the package's current state (for
/// example uninstalling a package that is not installed). [reason] is for
/// developers; show a localized message instead.
class PackageActionRejected extends HubException {
  final String id;
  final String reason;
  const PackageActionRejected(this.id, this.reason);

  @override
  String toString() => 'PackageActionRejected($id): $reason';
}

/// The package catalog could not be fetched or understood. [reason] is for
/// developers; show a localized message instead.
class CatalogUnavailable extends HubException {
  final Uri source;
  final String reason;
  const CatalogUnavailable(this.source, this.reason);

  @override
  String toString() => 'CatalogUnavailable($source): $reason';
}

/// The OS inventory could not be read. Never interpret this as no installs.
class InstalledSoftwareUnavailable extends HubException {
  final String reason;
  const InstalledSoftwareUnavailable(this.reason);

  @override
  String toString() => 'InstalledSoftwareUnavailable: $reason';
}

/// An installed application's executable could not be started.
class PackageLaunchFailed extends HubException {
  final String id;
  final String reason;
  const PackageLaunchFailed(this.id, this.reason);

  @override
  String toString() => 'PackageLaunchFailed($id): $reason';
}

class ApplicationProcessFailed extends HubException {
  final String reason;
  const ApplicationProcessFailed(this.reason);
  @override
  String toString() => 'ApplicationProcessFailed: $reason';
}
