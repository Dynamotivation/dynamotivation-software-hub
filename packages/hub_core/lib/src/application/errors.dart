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
