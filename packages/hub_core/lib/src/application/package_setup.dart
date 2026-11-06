import '../domain/software_package.dart';

/// A setup the hub can download and run for one package: the release
/// [version] and the catalog download that fits this device. The hub's own
/// update ([SelfUpdateOffer]) is one of these; installing or upgrading any
/// other software is another.
class SetupOffer {
  final String packageId;
  final String name;
  final String version;
  final DownloadLink setup;

  const SetupOffer({
    required this.packageId,
    required this.name,
    required this.version,
    required this.setup,
  });

  /// Where the catalog says the setup lives.
  Uri get url => Uri.parse(setup.url);
}

/// How a setup gets onto the device: [stage] downloads and verifies it into
/// the hub's own staging folder (reusing one already there), [run] runs it
/// silently and waits for it, [install] runs it detached once the hub has
/// quit (the hub's own update), [discard] and [clearStaged] remove staged
/// files. Implemented against the real installer with dart:io; tests supply
/// a fake.
abstract interface class SetupInstaller {
  /// Stages the setup [offer] points at and returns the file path. The
  /// folder of one package holds one staged version at a time; any other
  /// staged setup of that package goes first. Fails with a
  /// [SetupUnavailable] when the file cannot be downloaded or does not carry
  /// the digest the catalog promised.
  Future<String> stage(
    SetupOffer offer, {
    void Function(double progress)? onProgress,
  });

  /// Runs a staged setup silently and waits for it to finish. Returns the
  /// setup's exit code (0 is success). The setup writes its own log to
  /// [logFile]. Fails with a [SetupLaunchFailed] when it cannot be started.
  Future<int> run(String stagedFile, {required String logFile});

  /// Runs an installed app's registered [uninstaller] silently and waits
  /// for it. Returns its exit code (0 is success); it writes its own log to
  /// [logFile]. Fails with a [SetupLaunchFailed] when it cannot be started.
  Future<int> uninstall(String uninstaller, {required String logFile});

  /// Runs a staged setup silently, after this process has exited, and with
  /// [restart] opens the hub again afterwards. Never blocks for the setup.
  Future<void> install(String stagedFile, {required bool restart});

  /// Deletes one staged setup once it has served its purpose.
  Future<void> discard(String stagedFile);

  /// Deletes every staged, unfinished or superseded setup of the hub itself
  /// except [keep].
  Future<void> clearStaged({String? keep});
}

/// One release a user can pick to install ([HubUseCases.releaseChoices]).
class ReleaseChoice {
  final String version;
  final String date;

  /// False when the release offers no download this device runs.
  final bool installable;

  /// True for the version installed on the device.
  final bool isInstalled;
  final bool isLatest;

  const ReleaseChoice({
    required this.version,
    required this.date,
    required this.installable,
    required this.isInstalled,
    required this.isLatest,
  });

  /// Whether choosing it does anything.
  bool get selectable => installable && !isInstalled;
}

/// Where a running install or upgrade is, for a frontend to show.
sealed class SetupProgress {
  const SetupProgress();
}

/// The setup downloads; [fraction] runs from 0 to 1.
class SetupDownloading extends SetupProgress {
  final double fraction;
  const SetupDownloading(this.fraction);
}

/// The setup runs silently; there is no finer progress to report.
class SetupRunning extends SetupProgress {
  const SetupRunning();
}

/// Records what one install or upgrade did, for support and for the user.
abstract interface class InstallLog {
  /// Opens the record of installing [version] of [packageId].
  Future<InstallLogSession> start(String packageId, String version);
}

/// One install's record. [setupLogPath] is where the setup itself writes;
/// [close] folds that into [path].
abstract interface class InstallLogSession {
  String get path;
  String get setupLogPath;
  Future<void> write(String line);
  Future<void> close();
}

/// The catalog download for [platform] that runs on a device with [arch],
/// best first: the device's own architecture, then the ones it runs
/// ([runnableArchitectures]: 64-bit Windows runs 32-bit x86 builds), then
/// an arch-less download. Null when nothing offered runs here.
DownloadLink? pickSetup(
  List<DownloadLink> downloads,
  String platform,
  String arch,
) {
  final onPlatform = [
    for (final d in downloads)
      if (d.platform == platform) d,
  ];
  for (final candidate in runnableArchitectures(platform, arch)) {
    for (final d in onPlatform) {
      if (d.arch == candidate) return d;
    }
  }
  for (final d in onPlatform) {
    if (d.arch.isEmpty) return d;
  }
  return null;
}

/// The architectures a device with [arch] runs on [platform], preferred
/// first. Platform and architecture ids are open registry data; only the
/// well-known compatibility of Windows (WOW64, x64 emulation on Arm) and
/// macOS (Rosetta) is added, every other device runs its own architecture.
List<String> runnableArchitectures(String platform, String arch) =>
    switch ((platform, arch)) {
      ('windows', 'x64') => const ['x64', 'x86'],
      ('windows', 'arm64') => const ['arm64', 'x64', 'x86'],
      ('macos', 'arm64') => const ['arm64', 'x64'],
      _ => [arch],
    };
