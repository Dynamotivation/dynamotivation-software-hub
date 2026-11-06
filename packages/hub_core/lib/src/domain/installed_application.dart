/// An installation observed on the device, independently of any catalog.
class InstalledApplication {
  /// Stable identity supplied by the OS adapter (not a display name).
  final String id;
  final String name;
  final String version;

  /// The OS registration's main executable, or empty if none is known.
  final String launchExecutable;

  /// The registered uninstaller executable, or empty if none is usable.
  final String uninstallExecutable;

  const InstalledApplication({
    required this.id,
    required this.name,
    required this.version,
    this.launchExecutable = '',
    this.uninstallExecutable = '',
  });
}
