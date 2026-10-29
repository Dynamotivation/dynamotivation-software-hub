import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';

/// Presentation state of the Windows frontend. Holds no business rules; every
/// change goes through [HubUseCases].
class HubController extends ChangeNotifier {
  HubController(this._useCases, {this.onCatalogSynced});

  final HubUseCases _useCases;

  /// Called once a catalog load the user saw completes: the startup load and
  /// every successful manual refresh. The background update watch uses it to
  /// re-baseline itself so it never re-announces entries that were already
  /// visible on screen.
  final void Function()? onCatalogSynced;

  List<SoftwarePackage> _packages = const [];
  String? _selectedId;
  AppSettings _settings = const AppSettings();
  bool _isRefreshing = false;
  Object? _loadError;

  List<SoftwarePackage> get packages => _packages;

  /// Set when the catalog could not be loaded at startup. The page shows it once.
  Object? get loadError => _loadError;
  AppSettings get settings => _settings;
  bool get isRefreshing => _isRefreshing;

  SoftwarePackage? get selected {
    for (final p in _packages) {
      if (p.id == _selectedId) return p;
    }
    return null;
  }

  Future<void> load({String? preferredId}) async {
    _settings = await _useCases.loadSettings();
    try {
      _packages = await _useCases.listPackages();
      onCatalogSynced?.call();
    } on CatalogUnavailable catch (e) {
      _loadError = e;
      _packages = const [];
    }
    _selectedId = _packages.any((p) => p.id == preferredId)
        ? preferredId
        : _packages.firstOrNull?.id;
    notifyListeners();
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
      onCatalogSynced?.call();
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
