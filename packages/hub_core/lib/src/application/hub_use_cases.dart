import 'dart:async';
import 'dart:io' show Platform;

import '../domain/app_settings.dart';
import '../domain/software_package.dart';
import '../domain/software_version.dart';
import 'application_launcher.dart';
import 'application_processes.dart';
import 'catalog_reconciliation.dart';
import 'catalog_snapshot.dart';
import 'errors.dart';
import 'icon_store.dart';
import 'package_repository.dart';
import 'self_update.dart';
import 'settings_repository.dart';

/// The operations a frontend can perform. Frontends depend on this class,
/// never on repositories or aggregate internals directly.
class HubUseCases {
  final PackageRepository _packages;
  final SettingsRepository _settings;
  final IconStore? _icons;
  final ApplicationLauncher? _launcher;
  final ApplicationProcesses? _processes;
  final SetupInstaller? _installer;
  final InstallLog? _installLog;
  final String? _platform;
  final String? _arch;
  final Duration _uninstallSettle;

  // ignore: prefer_initializing_formals
  HubUseCases(
    this._packages,
    this._settings, {
    IconStore? icons,
    ApplicationLauncher? launcher,
    ApplicationProcesses? processes,
    SetupInstaller? installer,
    InstallLog? installLog,
    String? platform,
    String? arch,
    Duration uninstallSettle = const Duration(milliseconds: 500),
  })
    // ignore: prefer_initializing_formals
    : _icons = icons,
       // ignore: prefer_initializing_formals
       _launcher = launcher,
       // ignore: prefer_initializing_formals
       _processes = processes,
       // ignore: prefer_initializing_formals
       _installer = installer,
       // ignore: prefer_initializing_formals
       _installLog = installLog,
       // ignore: prefer_initializing_formals
       _platform = platform,
       // ignore: prefer_initializing_formals
       _arch = arch,
       // ignore: prefer_initializing_formals
       _uninstallSettle = uninstallSettle;

  /// The software to list. The hub itself is not part of it: it is not
  /// software to install from inside itself, and must not count in update
  /// totals or notifications. Its entry stays in the catalog data and is
  /// available through [currentCatalog] for the self-update lookup.
  Future<List<SoftwarePackage>> listPackages() async =>
      _splitHub(await _packages.all()).$1;

  /// The catalog as it is held now: the software to list plus the hub's own
  /// entry ([CatalogSnapshot.hub]) for [selfUpdateOffer].
  Future<CatalogSnapshot> currentCatalog() async {
    final (visible, hub) = _splitHub(await _packages.all());
    return CatalogSnapshot(visible, hub: hub, isFinal: true);
  }

  static (List<SoftwarePackage>, SoftwarePackage?) _splitHub(
    List<SoftwarePackage> all,
  ) => (
    [
      for (final p in all)
        if (p.id != hubPackageId) p,
    ],
    all.where((p) => p.id == hubPackageId).firstOrNull,
  );

  /// The last known catalog without waiting for the network, or null if the
  /// catalog source keeps none.
  Future<List<SoftwarePackage>?> cachedPackages() async {
    final source = _packages;
    final cached = source is CachedPackageSource
        ? await (source as CachedPackageSource).cachedPackages()
        : null;
    return cached == null ? null : _splitHub(cached).$1;
  }

  /// Opens the catalog the way a user should experience it: the last known
  /// catalog at once, then the fresh one settling in behind it. Emits
  /// [CatalogSnapshot]s; the last has [CatalogSnapshot.isFinal].
  ///
  /// With a cached catalog, the steps are:
  ///  1. the cached catalog;
  ///  2. text of known packages replaced, local state kept; packages that left
  ///     the catalog stay, marked departing, for [departGrace];
  ///  3. the departed removed;
  ///  4. each new package once its icon is stored (or failed to be), and each
  ///     changed icon once the new one is stored.
  /// Without a cache the sequence is the fresh catalog alone.
  ///
  /// Errors reach the stream. One before any snapshot means there is nothing
  /// to show; one after means the refresh failed behind a catalog already on
  /// screen.
  Stream<CatalogSnapshot> openCatalog({
    Duration departGrace = const Duration(milliseconds: 300),
  }) {
    final out = StreamController<CatalogSnapshot>();
    var cancelled = false;
    out.onCancel = () => cancelled = true;
    void emit(CatalogSnapshot s) {
      if (!cancelled) out.add(s);
    }

    Future<void> run() async {
      final source = _packages;
      final rawCache = source is CachedPackageSource
          ? await (source as CachedPackageSource).cachedPackages()
          : null;
      final (cachedVisible, cachedHub) = _splitHub(rawCache ?? const []);
      var hub = cachedHub;
      var shown = cachedVisible;
      final hadCache = shown.isNotEmpty;
      if (hadCache) emit(CatalogSnapshot(shown, hub: hub, fromCache: true));

      // Without a cache the first read is the load; with one, refresh it.
      if (hadCache) await _packages.refresh();
      final (fresh, freshHub) = _splitHub(await _packages.all());
      hub = freshHub;
      if (!hadCache) {
        emit(CatalogSnapshot(fresh, hub: hub, isFinal: true));
        return;
      }

      final plan = reconcileCatalog(shown, fresh);
      final updated = {for (final p in plan.textUpdated) p.id: p};
      final leaving = {
        for (final p in shown)
          if (!updated.containsKey(p.id)) p.id,
      };
      shown = [for (final p in shown) updated[p.id] ?? p];
      emit(CatalogSnapshot(shown, hub: hub, departing: leaving));
      if (leaving.isNotEmpty) {
        await Future<void>.delayed(departGrace);
        shown = [
          for (final p in shown)
            if (!leaving.contains(p.id)) p,
        ];
        emit(CatalogSnapshot(shown, hub: hub));
      }

      Future<void> ready(String? url) async {
        if (url != null) await _icons?.prefetch(url);
      }

      await Future.wait([
        for (final p in plan.added)
          () async {
            await ready(p.iconUrl);
            shown = [...shown, p]
              ..sort(
                (a, b) => plan.order
                    .indexOf(a.id)
                    .compareTo(plan.order.indexOf(b.id)),
              );
            emit(CatalogSnapshot(shown, hub: hub));
          }(),
        for (final p in plan.iconChanged)
          () async {
            await ready(p.iconUrl);
            shown = [
              for (final s in shown)
                s.id == p.id ? s.copyWith(iconUrl: p.iconUrl) : s,
            ];
            emit(CatalogSnapshot(shown, hub: hub));
          }(),
      ]);
      emit(CatalogSnapshot(shown, hub: hub, isFinal: true));
    }

    run()
        .catchError((Object error, StackTrace stack) {
          if (!cancelled) out.addError(error, stack);
        })
        .whenComplete(out.close);
    return out.stream;
  }

  Future<void> refreshCatalog() => _packages.refresh();

  /// The package with its older releases fetched, for the details view. The
  /// catalog carries only the latest release; this loads the rest. A source
  /// that has no separate history returns the package as it is.
  Future<SoftwarePackage> loadReleaseHistory(String id) async {
    final source = _packages;
    if (source is ReleaseHistorySource) {
      return (source as ReleaseHistorySource).loadReleaseHistory(id);
    }
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    return package;
  }

  /// Launching does not change installation state. OS failures are wrapped
  /// here so the frontend only needs a localized application error.
  Future<void> launchPackage(String id, {bool anotherInstance = false}) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    final launcher = _launcher;
    if (!package.canLaunch || launcher == null) {
      throw PackageActionRejected(id, 'No launchable installation is known.');
    }
    try {
      if (!anotherInstance &&
          _processes != null &&
          (await _processes.runningExecutables({package.launchExecutable}))
              .isNotEmpty) {
        throw PackageActionRejected(id, 'Application is already running.');
      }
      await launcher.launch(package.launchExecutable);
    } on PackageActionRejected {
      rethrow;
    } catch (error) {
      throw PackageLaunchFailed(id, error.toString());
    }
  }

  Future<Set<String>> runningPackageIds() async {
    final processes = _processes;
    if (processes == null) return {};
    final packages = await _packages.all();
    try {
      final running = await processes.runningExecutables({
        for (final p in packages)
          if (p.canLaunch) p.launchExecutable,
      });
      return {
        for (final p in packages)
          if (running.contains(p.launchExecutable)) p.id,
      };
    } catch (error) {
      throw ApplicationProcessFailed(error.toString());
    }
  }

  Future<void> forceClosePackage(String id) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    final processes = _processes;
    if (!package.canLaunch || processes == null) {
      throw PackageActionRejected(
        id,
        'No running installation can be controlled.',
      );
    }
    try {
      await processes.terminateAll(package.launchExecutable);
    } catch (error) {
      throw ApplicationProcessFailed(error.toString());
    }
  }

  /// Brings an installed package up to its latest release and returns it
  /// as the device shows it afterwards. See [installPackage].
  Future<SoftwarePackage> updatePackage(
    String id, {
    void Function(SetupProgress progress)? onProgress,
  }) => _runSetup(id, (p) => p.update(), onProgress);

  /// Installs the latest release of a package that is not on the device.
  /// Software read from the device runs its real setup: the download for
  /// this device is staged and verified like the hub's own update, run
  /// silently, recorded in the [InstallLog], and the device is read again.
  /// Only one setup runs at a time.
  Future<SoftwarePackage> installPackage(
    String id, {
    void Function(SetupProgress progress)? onProgress,
  }) => _runSetup(id, (p) => p.install(), onProgress);

  /// Every release of a package, newest first, for choosing one to install:
  /// fetches the release history first when it is not loaded yet. Releases
  /// without a download for this device are listed but not installable.
  Future<List<ReleaseChoice>> releaseChoices(String id) async {
    var package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    if (package.hasUnloadedHistory) package = await loadReleaseHistory(id);
    final installed = package.isInstalled ? package.currentVersion : null;
    return [
      for (final release in package.releases)
        ReleaseChoice(
          version: release.version,
          date: release.date,
          installable: _setupFor(release) != null,
          isInstalled:
              installed != null &&
              isSameSoftwareVersion(installed, release.version),
          isLatest: identical(release, package.latestRelease),
        ),
    ];
  }

  /// Installs a specific release, newer or older than the installed one
  /// (switching versions), the same way as [installPackage].
  Future<SoftwarePackage> installVersion(
    String id,
    String version, {
    void Function(SetupProgress progress)? onProgress,
  }) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    if (package.releaseOf(version) == null && package.hasUnloadedHistory) {
      await loadReleaseHistory(id);
    }
    return _runSetup(
      id,
      (p) => p.switchTo(version),
      onProgress,
      version: version,
    );
  }

  DownloadLink? _setupFor(ReleaseNote release) => pickSetup(
    release.downloads,
    _platform ?? Platform.operatingSystem,
    _arch ?? deviceArchitecture(),
  );

  /// The hub's own pending update from [packages] (the hub's entry,
  /// [CatalogSnapshot.hub], must be among them), or null when the catalog
  /// lists no newer release for itself or offers no download for this
  /// device. [installedVersion] is the running app's release version.
  /// [platform] and [arch] default to this device; callers may pin them.
  SelfUpdateOffer? selfUpdateOffer({
    required List<SoftwarePackage> packages,
    required String installedVersion,
    String? platform,
    String? arch,
  }) => evaluateSelfUpdate(
    packages: packages,
    installedVersion: installedVersion,
    platform: platform,
    arch: arch,
  );

  /// Stages the setup of [offer] in the app's own cache and returns the
  /// staged file's path. Requires the composition root to have wired a
  /// [SetupInstaller]; without one this is a [PackageActionRejected] that
  /// says no installer is available.
  Future<String> stageSelfUpdate(
    SelfUpdateOffer offer, {
    void Function(double progress)? onProgress,
  }) async {
    final installer = _installer;
    if (installer == null) {
      throw PackageActionRejected(
        hubPackageId,
        'No self-update installer is wired up.',
      );
    }
    return installer.stage(offer, onProgress: onProgress);
  }

  /// Runs a staged setup silently once the frontend has quit (the setup then
  /// finds no running Hub), and with [restart] opens the Hub again afterwards.
  Future<void> installSelfUpdate(
    String stagedFile, {
    required bool restart,
  }) async {
    final installer = _installer;
    if (installer == null) {
      throw PackageActionRejected(
        hubPackageId,
        'No self-update installer is wired up.',
      );
    }
    await installer.install(stagedFile, restart: restart);
  }

  /// Deletes staged setups other than [keep], e.g. leftovers from failed
  /// or superseded updates. The app may call it once at startup; failures
  /// reach the caller.
  Future<void> clearStagedSelfUpdates({String? keep}) async {
    final installer = _installer;
    if (installer == null) return;
    await installer.clearStaged(keep: keep);
  }

  bool _setupRunning = false;

  /// True while an install, update or uninstall runs.
  bool get isSetupRunning => _setupRunning;

  /// Runs the setup of [version] (the latest release when null) after the
  /// aggregate's [command] allowed it.
  Future<SoftwarePackage> _runSetup(
    String id,
    SoftwarePackage Function(SoftwarePackage) command,
    void Function(SetupProgress progress)? onProgress, {
    String? version,
  }) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    if (!package.deviceObserved) return _apply(id, command);

    // The aggregate decides whether the command is allowed; the device, not
    // the command's result, says what is installed afterwards.
    try {
      command(package);
    } on PackageStateException catch (e) {
      throw PackageActionRejected(id, e.message);
    }
    final installer = _installer;
    if (installer == null || _installLog == null) {
      throw PackageActionRejected(id, 'No setup installer is wired up.');
    }
    final release = version == null
        ? package.latestRelease
        : package.releaseOf(version)!;
    final link = _setupFor(release);
    if (link == null) {
      throw PackageActionRejected(id, 'No download for this device.');
    }
    final offer = SetupOffer(
      packageId: id,
      name: package.name,
      version: release.version,
      setup: link,
    );
    final exact = version != null;

    return _inSetupSession(id, offer.version, (session) async {
      await session.write(
        '${package.isInstalled ? (exact ? 'Switch' : 'Update') : 'Install'} '
        '${package.name} '
        '${package.isInstalled ? '${package.currentVersion} -> ' : ''}'
        '${offer.version}',
      );
      if (package.isInstalled) await _refuseWhileRunning(package, session);
      await session.write(
        'Download ${link.url} (${link.size} bytes, sha256 ${link.sha256})',
      );
      onProgress?.call(const SetupDownloading(0));
      final String staged;
      try {
        staged = await installer.stage(
          offer,
          onProgress: (f) => onProgress?.call(SetupDownloading(f)),
        );
      } catch (error) {
        await session.write('Download failed: $error');
        rethrow;
      }
      await session.write('Verified $staged');
      onProgress?.call(const SetupRunning());
      await session.write('Run silently: $staged');
      final int exitCode;
      try {
        exitCode = await installer.run(staged, logFile: session.setupLogPath);
      } catch (error) {
        await session.write('Setup did not start: $error');
        rethrow;
      } finally {
        await installer.discard(staged);
      }
      await session.write('Setup exit code $exitCode');
      if (exitCode != 0) throw SetupFailed(id, exitCode, session.path);

      await _rescanDevice();
      final after = await _packages.find(id);
      final installedVersion = after?.isInstalled == true
          ? after!.currentVersion
          : null;
      await session.write('Device reports ${installedVersion ?? 'nothing'}');
      // A chosen version must be exactly that one; the latest release at
      // least that new.
      if (after == null ||
          installedVersion == null ||
          (exact
              ? !isSameSoftwareVersion(offer.version, installedVersion)
              : isNewerSoftwareVersion(offer.version, installedVersion))) {
        throw SetupFailed(id, null, session.path);
      }
      return after;
    });
  }

  /// Removes an installed package. Software read from the device runs its
  /// registered uninstaller silently, recorded in the [InstallLog], and the
  /// device is read again until the package is gone. Returns the package as
  /// the hub lists it afterwards; software the catalog does not list leaves
  /// the list and comes back in the state the domain command gives it.
  Future<SoftwarePackage> uninstallPackage(
    String id, {
    void Function(SetupProgress progress)? onProgress,
  }) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    if (!package.deviceObserved) return _apply(id, (p) => p.uninstall());
    final SoftwarePackage removed;
    try {
      removed = package.uninstall();
    } on PackageStateException catch (e) {
      throw PackageActionRejected(id, e.message);
    }
    final installer = _installer;
    if (!package.canUninstall || installer == null || _installLog == null) {
      throw PackageActionRejected(id, 'No uninstaller is registered.');
    }
    return _inSetupSession(id, package.currentVersion, (session) async {
      await session.write(
        'Uninstall ${package.name} ${package.currentVersion}',
      );
      await _refuseWhileRunning(package, session);
      onProgress?.call(const SetupRunning());
      await session.write('Run silently: ${package.uninstallExecutable}');
      final int exitCode;
      try {
        exitCode = await installer.uninstall(
          package.uninstallExecutable,
          logFile: session.setupLogPath,
        );
      } catch (error) {
        await session.write('Uninstaller did not start: $error');
        rethrow;
      }
      await session.write('Uninstaller exit code $exitCode');
      if (exitCode != 0) throw SetupFailed(id, exitCode, session.path);

      // Inno's uninstaller finishes in a copy of itself; wait for the
      // registration to go.
      SoftwarePackage? after;
      for (var attempt = 0; attempt < 20; attempt++) {
        await _rescanDevice();
        after = await _packages.find(id);
        if (after == null || !after.isInstalled) break;
        await Future<void>.delayed(_uninstallSettle);
      }
      final still = after != null && after.isInstalled;
      await session.write(
        'Device reports ${still ? after.currentVersion : 'nothing'}',
      );
      if (still) throw SetupFailed(id, null, session.path);
      return after ?? removed;
    });
  }

  /// One setup at a time, each with its own log that records how it ended.
  Future<T> _inSetupSession<T>(
    String id,
    String version,
    Future<T> Function(InstallLogSession session) body,
  ) async {
    final log = _installLog;
    if (log == null) {
      throw PackageActionRejected(id, 'No install log is wired up.');
    }
    if (_setupRunning) {
      throw PackageActionRejected(id, 'Another setup is running.');
    }
    _setupRunning = true;
    InstallLogSession? session;
    try {
      session = await log.start(id, version);
      final result = await body(session);
      await session.write('Done');
      return result;
    } catch (error) {
      await session?.write('Failed: $error');
      rethrow;
    } finally {
      await session?.close();
      _setupRunning = false;
    }
  }

  /// A running app cannot be replaced or removed; close it first.
  Future<void> _refuseWhileRunning(
    SoftwarePackage package,
    InstallLogSession session,
  ) async {
    if ((await runningPackageIds()).contains(package.id)) {
      await session.write('Refused: ${package.name} is running.');
      throw PackageInUse(package.id);
    }
  }

  /// Reads the device again, without a network request where possible.
  Future<void> _rescanDevice() async {
    final source = _packages;
    if (source is DeviceInventorySource) {
      await (source as DeviceInventorySource).rescanDevice();
    } else {
      await _packages.refresh();
    }
  }

  /// Runs a lifecycle command on the stored package. Domain refusals are
  /// rethrown as [PackageActionRejected] so frontends only handle [HubException].
  Future<SoftwarePackage> _apply(
    String id,
    SoftwarePackage Function(SoftwarePackage) command,
  ) async {
    final package = await _packages.find(id);
    if (package == null) throw PackageNotFound(id);
    if (package.deviceObserved) {
      throw PackageActionRejected(id, 'Package management is not implemented.');
    }
    final SoftwarePackage changed;
    try {
      changed = command(package);
    } on PackageStateException catch (e) {
      throw PackageActionRejected(id, e.message);
    }
    await _packages.save(changed);
    return changed;
  }

  Future<AppSettings> loadSettings() => _settings.load();

  Future<void> saveSettings(AppSettings settings) => _settings.save(settings);
}
