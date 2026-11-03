import 'dart:io' show Platform;

import '../domain/software_package.dart';

/// The catalog page of the hub itself, its id follows the page slug. When
/// the website lists the Software Hub among its software, the app reads its
/// pending update from the same catalog it serves to the user.
const hubPackageId = 'dynamotivation-software-hub';

/// How the hub's next version gets in: [stage] downloads and verifies the
/// newest setup into the app's own staging folder, [install] runs it
/// silently (callers quit the app right after), [clearStaged] removes
/// staged leftovers. Implemented against the real installer with dart:io;
/// tests supply a fake.
abstract interface class SetupInstaller {
  /// Stages the setup [offer] points at and returns the file path. The
  /// folder holds one staged version at a time; any other staged setup
  /// goes first. Fails with a [SetupUnavailable] when the file cannot be
  /// downloaded or does not carry the digest the catalog promised.
  Future<String> stage(
    SelfUpdateOffer offer, {
    void Function(double progress)? onProgress,
  });

  /// Runs a staged setup silently. Never blocks for the setup process.
  Future<void> install(String stagedFile);

  /// Deletes every staged, unfinished or superseded setup except [keep].
  /// Belt-and-braces for the installer's own cleanup; a stub the app runs
  /// once at startup, so it may be empty when nothing remains.
  Future<void> clearStaged({String? keep});
}

/// The hub's own pending update, as the catalog offers it: the hub software
/// entry plus the download that fits this device.
class SelfUpdateOffer {
  final SoftwarePackage hub;
  final DownloadLink setup;

  const SelfUpdateOffer({required this.hub, required this.setup});

  /// The version the update brings.
  String get version => hub.latestVersion;
  String get name => hub.name;

  /// Where the catalog says the setup lives.
  Uri get url => Uri.parse(setup.url);
}

/// The hub's own update from a catalog, if the catalog lists the hub with a
/// release newer than [installedVersion] and offers a download for
/// [platform]/[arch]. Device defaults come from dart:io; a frontend may
/// pass them for tests or preview runs.
SelfUpdateOffer? evaluateSelfUpdate({
  required List<SoftwarePackage> packages,
  required String installedVersion,
  String? platform,
  String? arch,
}) {
  platform ??= Platform.operatingSystem;
  arch ??= deviceArchitecture();
  final SoftwarePackage? hub;
  try {
    hub = packages.firstWhere((p) => p.id == hubPackageId);
  } on StateError {
    return null;
  }
  if (compareVersions(hub.latestVersion, installedVersion) <= 0) {
    return null;
  }
  final link = _pickSetup(hub.latestRelease.downloads, platform, arch);
  if (link == null) return null;
  return SelfUpdateOffer(hub: hub, setup: link);
}

/// The catalog download that matches [platform] and, where possible, [arch].
/// An arch-less download ('' as the registry allows for builds without a
/// dedicated architecture) matches when no exact architecture is offered;
/// one for another architecture never matches.
DownloadLink? _pickSetup(List<DownloadLink> downloads, String platform, String arch) {
  final candidates = [
    for (final d in downloads)
      if (d.platform == platform &&
          (d.arch == arch || (arch.isEmpty && d.arch.isEmpty)))
        d,
  ];
  for (final d in candidates) {
    if (d.arch == arch) return d;
  }
  return candidates.isEmpty ? null : candidates.first;
}

/// The CPU architecture the hub runs on, in the website's registry spellings
/// ('x64', 'arm64', ...). Unknown platforms report '' and then match
/// any downloads.
String deviceArchitecture({String? operatingSystem, Map<String, String>? environment}) {
  final env = environment ?? Platform.environment;
  switch (operatingSystem ?? Platform.operatingSystem) {
    case 'windows':
      return switch (env['PROCESSOR_ARCHITECTURE']) {
        'AMD64' => 'x64',
        'ARM64' => 'arm64',
        'x86' => 'x86',
        _ => '',
      };
    case 'macos':
      return env['PROCESSOR_ARCHITECTURE'] == 'arm64' ? 'arm64' : 'x64';
    case 'linux':
      return switch (env['ARCH']) {
        'x86_64' => 'x64',
        'aarch64' => 'arm64',
        'i686' => 'x86',
        _ => '',
      };
    default:
      return '';
  }
}

/// Compares two release version strings of the shape the website publishes
/// (`1.2`, `1.2.3`, optional `-pre` or `+build` suffix). Numeric segments
/// only; a version is older when it runs out compared with the other.
/// 1 < 2, etc. Empty segments count as 0. Returns negative, 0 or positive.
int compareVersions(String a, String b) {
  final left = _segments(a);
  final right = _segments(b);
  final length = left.length > right.length ? left.length : right.length;
  for (var i = 0; i < length; i++) {
    final current = i < left.length ? left[i] : 0;
    final other = i < right.length ? right[i] : 0;
    if (current != other) return current.compareTo(other);
  }
  return 0;
}

/// True when [a] is strictly older than [b].
bool versionIsOlder(String a, String b) => compareVersions(a, b) < 0;

List<int> _segments(String version) {
  final core = version.split(RegExp(r'[-+]')).first;
  return [
    for (final segment in core.split('.')) int.tryParse(segment, radix: 10) ?? 0,
  ];
}
