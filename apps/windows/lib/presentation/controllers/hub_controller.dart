import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:hub_core/hub_core.dart';

/// A message the hub shows inside its own window, e.g. what the background
/// watch found while the window is focused. It stays until dismissed.
class HubNotice {
  const HubNotice({
    required this.id,
    required this.title,
    required this.message,
  });

  /// Unique per notice, to key the widget and to dismiss it.
  final int id;
  final String title;
  final String message;
}

/// Presentation state of the Windows frontend. Holds no business rules; every
/// change goes through [HubUseCases].
class HubController extends ChangeNotifier {
  HubController(
    this._useCases, {
    this.onStartupSynced,
    this.onCatalogSynced,
    this.departDuration = const Duration(milliseconds: 300),
    this.selfVersion = '0.0.0',
    this.selfPlatform,
    this.selfArch,
    this.quitForUpdate,
  });

  final HubUseCases _useCases;
  Timer? _processTimer;
  int _watchGeneration = 0;
  Set<String> _runningIds = {};
  final Set<String> _launchingIds = {};
  bool _checkingProcesses = false;
  bool isRunning(String id) => _runningIds.contains(id);
  bool isLaunching(String id) => _launchingIds.contains(id);

  void stopProcessWatch() {
    _watchGeneration++;
    _processTimer?.cancel();
    _processTimer = null;
  }

  Future<void> startProcessWatch() async {
    if (_disposed) return;
    final generation = ++_watchGeneration;
    try {
      await refreshRunningProcesses();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'hub process monitor',
        ),
      );
    }
    if (_disposed || generation != _watchGeneration) return;
    _processTimer ??= Timer.periodic(const Duration(seconds: 2), (_) async {
      try {
        await refreshRunningProcesses();
      } catch (error, stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'hub process monitor',
          ),
        );
      }
    });
  }

  Future<void> refreshRunningProcesses() async {
    if (_disposed || _checkingProcesses) return;
    _checkingProcesses = true;
    try {
      final running = await _useCases.runningPackageIds();
      if (_disposed) return;
      if (!setEquals(running, _runningIds)) {
        _runningIds = running;
        notifyListeners();
      }
    } finally {
      _checkingProcesses = false;
    }
  }

  Future<void> forceClosePackage(String id) async {
    if (!_launchingIds.add(id)) return;
    notifyListeners();
    try {
      await _useCases.forceClosePackage(id);
      await refreshRunningProcesses();
    } finally {
      _launchingIds.remove(id);
      if (!_disposed) notifyListeners();
    }
  }

  /// The release version the running app knows of itself, from
  /// `package_info_plus` in the composition root. Drives the hub's own
  /// update comparison (`selfUpdateOffer`).
  final String selfVersion;

  /// Platform and architecture the pending update is looked up for; null
  /// means this device. Tests pin them so they do not depend on the host.
  final String? selfPlatform;
  final String? selfArch;

  /// Called right after the staged self-update setup was launched, so the
  /// process leaves and the installer replaces it. The composition root
  /// wires this once its background surface exists; unwired (design
  /// previews), the app keeps running and the setup closes it itself
  /// ([CloseApplications=yes] in the shared installer settings).
  Future<void> Function()? quitForUpdate;

  /// Called once when the catalog opened at startup has settled (its final
  /// snapshot). The background surface announces from here what the user was
  /// not told about before the app was last closed.
  final void Function()? onStartupSynced;

  /// Called after every successful manual refresh. The background update
  /// watch uses it to record what the user just saw on screen as known, so
  /// it never announces it afterwards.
  final void Function()? onCatalogSynced;

  /// How long a package that left the catalog stays listed, marked in
  /// [departingIds], so the list can fade it out before it is removed.
  final Duration departDuration;

  /// Completes when the catalog stream opened by [load] has ended, i.e. the
  /// background refresh is done. Never fails (errors are reported).
  Future<void>? revalidation;

  StreamSubscription<CatalogSnapshot>? _catalog;
  Set<String> _departing = const {};

  List<SoftwarePackage> _packages = const [];
  String? _selectedId;
  AppSettings _settings = const AppSettings();
  bool _isRefreshing = false;
  Object? _loadError;
  bool _disposed = false;
  final Set<String> _loadingHistory = {};
  final Map<String, Object> _historyErrors = {};

  /// The hub's own catalog entry. Kept out of [packages] (the hub does not
  /// list itself) but needed to find its pending update.
  SoftwarePackage? _hub;

  final List<HubNotice> _notices = [];
  int _nextNoticeId = 1;

  SelfUpdateOffer? _hubUpdate;
  bool _isStagingHubUpdate = false;
  double _hubStageProgress = 0.0;

  /// Path of the verified setup of [_hubUpdate], once it is downloaded.
  String? _stagedSetup;

  /// The version a failed background download was for; not retried until a
  /// newer version appears or the user asks.
  String? _failedStageVersion;
  bool _updateLaunched = false;

  /// The hub's own pending update, or null when the catalog offers none for
  /// this machine. Recomputed with every catalog view the controller shows.
  SelfUpdateOffer? get hubUpdate => _hubUpdate;

  /// True while the setup of the pending update downloads.
  bool get isStagingHubUpdate => _isStagingHubUpdate;

  /// True once the pending update is downloaded and verified: it installs
  /// with "restart to update" or, failing that, when the app closes.
  bool get isHubUpdateReady => _stagedSetup != null && _hubUpdate != null;

  /// Download progress of the setup, 0 to 1, while staging.
  double get hubStageProgress => _hubStageProgress;

  List<SoftwarePackage> get packages => _packages;

  /// In-app notifications, oldest first, until the user dismisses them.
  List<HubNotice> get notices => List.unmodifiable(_notices);

  /// Shows a notification inside the window. It neither moves focus nor
  /// expires on its own.
  void postNotice({required String title, required String message}) {
    _notices.add(
      HubNotice(id: _nextNoticeId++, title: title, message: message),
    );
    notifyListeners();
  }

  void dismissNotice(int id) {
    _notices.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  /// Packages the catalog no longer lists, still shown while they fade out.
  Set<String> get departingIds => _departing;

  /// Set when the catalog could not be loaded at startup. The page shows it once.
  Object? get loadError => _loadError;
  AppSettings get settings => _settings;
  bool get isRefreshing => _isRefreshing;

  /// True while the older releases of [id] are being fetched.
  bool isLoadingHistory(String id) => _loadingHistory.contains(id);

  /// Why the older releases of [id] could not be fetched, until a retry.
  Object? historyError(String id) => _historyErrors[id];

  SoftwarePackage? get selected {
    for (final p in _packages) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  /// Opens the catalog and returns once something can be shown: the cached
  /// catalog straight away, else the first network load. The rest of the
  /// refresh keeps updating the controller afterwards.
  Future<void> load({String? preferredId}) async {
    _settings = await _useCases.loadSettings();
    final firstShown = Completer<void>();
    final finished = Completer<void>();
    revalidation = finished.future;
    var shownAny = false;
    _catalog = _useCases
        .openCatalog(departGrace: departDuration)
        .listen(
          (snapshot) {
            _show(snapshot, preferredId, first: !shownAny);
            shownAny = true;
            if (!firstShown.isCompleted) firstShown.complete();
            if (snapshot.isFinal) onStartupSynced?.call();
          },
          onError: (Object error, StackTrace stack) {
            if (!shownAny &&
                (error is CatalogUnavailable ||
                    error is InstalledSoftwareUnavailable)) {
              _loadError = error;
              notifyListeners();
            } else if (!shownAny) {
              if (!firstShown.isCompleted) {
                firstShown.completeError(error, stack);
              }
              return;
            } else {
              FlutterError.reportError(
                FlutterErrorDetails(
                  exception: error,
                  stack: stack,
                  library: 'hub catalog refresh',
                ),
              );
            }
            if (!firstShown.isCompleted) firstShown.complete();
          },
          onDone: () {
            if (!firstShown.isCompleted) firstShown.complete();
            finished.complete();
          },
        );
    await firstShown.future;
  }

  /// Takes over what the use case says to list. A selection that left the
  /// catalog moves to its neighbour in the old list, not back to the top.
  void _show(
    CatalogSnapshot snapshot,
    String? preferredId, {
    required bool first,
  }) {
    final old = _packages;
    _hub = snapshot.hub;
    // The catalog entry carries no older releases; keep the ones already fetched.
    _packages = [
      for (final p in snapshot.packages)
        switch (old.where((o) => o.id == p.id).firstOrNull) {
          final o?
              when o.latestVersion == p.latestVersion &&
                  o.olderReleases.length > p.olderReleases.length =>
            p.copyWith(
              olderReleases: o.olderReleases,
              availableVersions: o.availableVersions,
            ),
          _ => p,
        },
    ];
    _departing = snapshot.departing;
    if (first) {
      _selectedId = _packages.any((p) => p.id == preferredId)
          ? preferredId
          : _packages.firstOrNull?.id;
    } else if (!_packages.any((p) => p.id == _selectedId)) {
      final at = old.indexWhere((p) => p.id == _selectedId);
      bool kept(SoftwarePackage p) => _packages.any((n) => n.id == p.id);
      final after = at < 0 ? const <SoftwarePackage>[] : old.skip(at + 1);
      final before = at < 0
          ? const <SoftwarePackage>[]
          : old.take(at).toList().reversed;
      _selectedId =
          (after.where(kept).firstOrNull ??
                  before.where(kept).firstOrNull ??
                  _packages.firstOrNull)
              ?.id;
    }
    notifyListeners();
    loadSelectedHistory();
    _recomputeHubUpdate();
  }

  /// Fetches the older releases of the selected package if the catalog listed
  /// only its latest one. Starts as soon as the details view opens.
  void loadSelectedHistory() {
    final id = _selectedId;
    if (id != null) unawaited(loadHistory(id));
  }

  /// Fetches the older releases of [id] once; a failure is kept in
  /// [historyError] for the details view to show, and a call retries it.
  Future<void> loadHistory(String id) async {
    final package = _packages.where((p) => p.id == id).firstOrNull;
    if (package == null ||
        !package.hasUnloadedHistory ||
        _loadingHistory.contains(id)) {
      return;
    }
    _loadingHistory.add(id);
    _historyErrors.remove(id);
    notifyListeners();
    try {
      final loaded = await _useCases.loadReleaseHistory(id);
      _packages = [
        for (final p in _packages)
          p.id == id && p.latestVersion == loaded.latestVersion
              ? p.copyWith(
                  olderReleases: loaded.olderReleases,
                  availableVersions: loaded.availableVersions,
                )
              : p,
      ];
    } catch (error) {
      _historyErrors[id] = error;
    } finally {
      _loadingHistory.remove(id);
      if (!_disposed) notifyListeners();
    }
  }

  /// "Restart to update": installs the downloaded update (downloading it
  /// first if that has not happened yet), and leaves the app through
  /// [quitForUpdate]; the setup runs once the process is gone and opens the
  /// hub again. A failed download is rethrown for the page to present.
  Future<void> updateHub() async {
    if (_hubUpdate == null || _isStagingHubUpdate || _updateLaunched) return;
    if (_stagedSetup == null) await _stageHubUpdate(_hubUpdate!);
    final staged = _stagedSetup;
    if (staged == null) return;
    await _useCases.installSelfUpdate(staged, restart: true);
    _updateLaunched = true;
    await quitForUpdate?.call();
  }

  /// Called as the process ends (window closed without a tray, or the tray's
  /// End): a downloaded update installs now, silently, without reopening.
  /// Failures are reported, never block quitting.
  Future<void> installStagedOnExit() async {
    final staged = _stagedSetup;
    if (staged == null || _hubUpdate == null || _updateLaunched) return;
    _updateLaunched = true;
    try {
      await _useCases.installSelfUpdate(staged, restart: false);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'hub self-update',
        ),
      );
    }
  }

  Future<void> _stageHubUpdate(SelfUpdateOffer offer) async {
    _isStagingHubUpdate = true;
    _hubStageProgress = 0.0;
    notifyListeners();
    try {
      _stagedSetup = await _useCases.stageSelfUpdate(
        offer,
        onProgress: (progress) {
          _hubStageProgress = progress;
          notifyListeners();
        },
      );
      _failedStageVersion = null;
    } catch (_) {
      _failedStageVersion = offer.version;
      rethrow;
    } finally {
      _isStagingHubUpdate = false;
      notifyListeners();
    }
  }

  /// With automatic updates on, a pending update downloads in the background
  /// as soon as the catalog offers it. Nobody is waiting, so a failure is
  /// reported, not shown.
  Future<void> _stageInBackground(SelfUpdateOffer offer) async {
    try {
      await _stageHubUpdate(offer);
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'hub self-update download',
        ),
      );
    }
  }

  /// Asks the use cases whether the catalog offers the hub itself an update
  /// for this device. A failure to compare (malformed entry) is not worth a
  /// user error: the offer just stays absent.
  void _recomputeHubUpdate() {
    final SelfUpdateOffer? offer;
    try {
      offer = _useCases.selfUpdateOffer(
        packages: [?_hub],
        installedVersion: selfVersion,
        platform: selfPlatform,
        arch: selfArch,
      );
    } catch (error) {
      FlutterError.reportError(
        FlutterErrorDetails(exception: error, library: 'hub self-update offer'),
      );
      _hubUpdate = null;
      return;
    }
    if (offer?.version != _hubUpdate?.version) _stagedSetup = null;
    _hubUpdate = offer;
    if (offer == null) {
      // Nothing pending: whatever is staged is stale (an update that went
      // through, or one the website withdrew).
      if (!_updateLaunched) {
        _useCases.clearStagedSelfUpdates().catchError((
          Object error,
          StackTrace stack,
        ) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'hub self-update cleanup',
            ),
          );
        });
      }
    } else if (_settings.autoCheckUpdates &&
        _stagedSetup == null &&
        !_isStagingHubUpdate &&
        _failedStageVersion != offer.version) {
      _stageInBackground(offer);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    stopProcessWatch();
    _catalog?.cancel();
    super.dispose();
  }

  void select(SoftwarePackage package) {
    _selectedId = package.id;
    notifyListeners();
    loadSelectedHistory();
    _recomputeHubUpdate();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _useCases.saveSettings(settings);
    _recomputeHubUpdate(); // turning automatic updates on starts a pending download
  }

  /// Adopts what the catalog source holds now, without fetching. The hourly
  /// background check refreshes the source while the window is hidden; this
  /// brings the controller (and so the reopened window) along.
  Future<void> syncFromSource() async {
    if (_disposed) return;
    final fresh = await _useCases.currentCatalog();
    if (_disposed) return;
    _show(fresh, null, first: false);
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      await _useCases.refreshCatalog();
      final catalog = await _useCases.currentCatalog();
      _packages = catalog.packages;
      _hub = catalog.hub;
      _recomputeHubUpdate();
      onCatalogSynced?.call();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
    loadSelectedHistory();
  }

  /// Updates the selected package. Throws [HubException] or
  /// [PackageStateException] on failure.
  Future<SoftwarePackage> updateSelected() async {
    final id = _selectedId;
    if (id == null) throw const PackageNotFound('');
    final updated = await _useCases.updatePackage(id);
    _packages = await _useCases.listPackages();
    notifyListeners();
    return updated;
  }

  Future<void> launchSelected({bool anotherInstance = false}) async {
    final id = _selectedId;
    if (id == null) throw const PackageNotFound('');
    if (!_launchingIds.add(id)) return;
    notifyListeners();
    try {
      await _useCases.launchPackage(id, anotherInstance: anotherInstance);
      _runningIds = {..._runningIds, id};
    } finally {
      _launchingIds.remove(id);
      if (!_disposed) notifyListeners();
    }
  }

  Future<SoftwarePackage> installSelected() =>
      _runOnSelected(_useCases.installPackage);

  Future<SoftwarePackage> uninstallSelected() =>
      _runOnSelected(_useCases.uninstallPackage);

  Future<SoftwarePackage> _runOnSelected(
    Future<SoftwarePackage> Function(String id) command,
  ) async {
    final id = _selectedId;
    if (id == null) throw const PackageNotFound('');
    final result = await command(id);
    _packages = await _useCases.listPackages();
    notifyListeners();
    return result;
  }
}
