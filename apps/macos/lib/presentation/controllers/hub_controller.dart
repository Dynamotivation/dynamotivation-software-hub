import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hub_core/hub_core.dart';

/// Presentation state of the macOS frontend. Holds no business rules; every
/// change goes through [HubUseCases].
class HubController extends ChangeNotifier {
  final HubUseCases _useCases;

  HubController(this._useCases);

  StreamSubscription<CatalogSnapshot>? _catalog;
  List<SoftwarePackage> _packages = const [];
  String? _selectedId;
  AppSettings _settings = const AppSettings();
  bool _isRefreshing = false;

  List<SoftwarePackage> get packages => _packages;
  AppSettings get settings => _settings;
  bool get isRefreshing => _isRefreshing;

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
    var shownAny = false;
    _catalog = _useCases
        .openCatalog(departGrace: Duration.zero)
        .listen(
          (snapshot) {
            final first = !shownAny;
            shownAny = true;
            _packages = snapshot.packages;
            if (first) {
              _selectedId = _packages.any((p) => p.id == preferredId)
                  ? preferredId
                  : _packages.firstOrNull?.id;
            } else if (!_packages.any((p) => p.id == _selectedId)) {
              _selectedId = _packages.firstOrNull?.id;
            }
            notifyListeners();
            if (!firstShown.isCompleted) firstShown.complete();
          },
          onError: (Object error, StackTrace stack) {
            if (shownAny) {
              FlutterError.reportError(
                FlutterErrorDetails(exception: error, stack: stack),
              );
            } else if (!firstShown.isCompleted) {
              firstShown.completeError(error, stack);
            }
          },
          onDone: () {
            if (!firstShown.isCompleted) firstShown.complete();
          },
        );
    await firstShown.future;
  }

  @override
  void dispose() {
    _catalog?.cancel();
    super.dispose();
  }

  void select(SoftwarePackage package) {
    _selectedId = package.id;
    notifyListeners();
  }

  Future<void> updateSettings(AppSettings settings) async {
    _settings = settings;
    notifyListeners();
    await _useCases.saveSettings(settings);
  }

  Future<void> refresh() async {
    _isRefreshing = true;
    notifyListeners();
    try {
      await _useCases.refreshCatalog();
      _packages = await _useCases.listPackages();
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
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
