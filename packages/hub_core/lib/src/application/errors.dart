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

class PackageAlreadyRegistered extends HubException {
  final String id;
  const PackageAlreadyRegistered(this.id);

  @override
  String toString() => 'PackageAlreadyRegistered($id)';
}

class InvalidPackageName extends HubException {
  const InvalidPackageName();

  @override
  String toString() => 'InvalidPackageName()';
}
