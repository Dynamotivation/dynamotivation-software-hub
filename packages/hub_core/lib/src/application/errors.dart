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

/// The setup of an update could not be downloaded, or does not match the
/// digest and size the catalog promised. [reason] is for developers; show a
/// localized message instead.
class SetupUnavailable extends HubException {
  final Uri source;
  final String reason;
  const SetupUnavailable(this.source, this.reason);

  @override
  String toString() => 'SetupUnavailable($source): $reason';
}

/// A staged setup could not be started. [reason] is for developers; show a
/// localized message instead.
class SetupLaunchFailed extends HubException {
  final String path;
  final String reason;
  const SetupLaunchFailed(this.path, this.reason);

  @override
  String toString() => 'SetupLaunchFailed($path): $reason';
}

/// A setup ran but did not install the software: it ended with
/// [exitCode], or the device does not show the new version afterwards
/// (null [exitCode]). [logPath] holds what happened.
class SetupFailed extends HubException {
  final String id;
  final int? exitCode;
  final String logPath;
  const SetupFailed(this.id, this.exitCode, this.logPath);

  @override
  String toString() => 'SetupFailed($id): exit $exitCode, log $logPath';
}

/// The software runs, so its setup cannot replace it. Close it first.
class PackageInUse extends HubException {
  final String id;
  const PackageInUse(this.id);

  @override
  String toString() => 'PackageInUse($id)';
}
