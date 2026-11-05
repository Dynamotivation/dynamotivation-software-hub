import 'dart:async';

import 'package:fluent_ui/fluent_ui.dart';
import 'package:flutter/foundation.dart' show setEquals;
import 'package:hub_core/hub_core.dart';

/// Presentation state of the Windows frontend. Holds no business rules; every
/// change goes through [HubUseCases].
class HubController extends ChangeNotifier {
  HubController(
    this._useCases, {
    this.onCatalogSynced,
    this.departDuration = const Duration(milliseconds: 300),
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

  /// Called once a catalog load the user saw completes: the startup load and
  /// every successful manual refresh. The background update watch uses it to
  /// re-baseline itself so it never re-announces entries that were already
  /// visible on screen.
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

  List<SoftwarePackage> get packages => _packages;

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
            if (snapshot.isFinal) onCatalogSynced?.call();
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
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _useCases.saveSettings(settings);
  }

  /// Takes over the successful background poll without fetching a second time.
  Future<void> syncFromSource() async {
    final packages = await _useCases.listPackages();
    if (_disposed) return;
    _show(CatalogSnapshot(packages, isFinal: true), null, first: false);
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      await _useCases.refreshCatalog();
      _packages = await _useCases.listPackages();
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
