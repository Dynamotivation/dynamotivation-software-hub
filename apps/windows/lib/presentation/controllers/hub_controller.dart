import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';

/// Presentation state of the Windows frontend. Holds no business rules; every
/// change goes through [HubUseCases].
class HubController extends ChangeNotifier {
  final HubUseCases _useCases;

  HubController(this._useCases);

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

  Future<void> load({String? preferredId}) async {
    _settings = await _useCases.loadSettings();
    _packages = await _useCases.listPackages();
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

  /// Throws [HubException] on failure.
  Future<SoftwarePackage> register({
    required String name,
    required String subtitle,
    required String description,
    required String initialHighlight,
  }) async {
    final created = await _useCases.registerPackage(
      name: name,
      subtitle: subtitle,
      description: description,
      initialHighlight: initialHighlight,
    );
    _packages = await _useCases.listPackages();
    _selectedId = created.id;
    notifyListeners();
    return created;
  }
}
