import 'package:fluent_ui/fluent_ui.dart';
import 'package:hub_core/hub_core.dart';

/// Presentation state of the Windows frontend. Holds no business rules; every
/// change goes through [HubUseCases].
class HubController extends ChangeNotifier {
  HubController(
    this._useCases, {
    this.onCatalogSynced,
    this.preloadIcon,
    this.departDuration = const Duration(milliseconds: 300),
  });

  final HubUseCases _useCases;

  /// Called once a catalog load the user saw completes: the startup load and
  /// every successful manual refresh. The background update watch uses it to
  /// re-baseline itself so it never re-announces entries that were already
  /// visible on screen.
  final void Function()? onCatalogSynced;

  /// Waits until an icon is ready (loaded or failed). Without it, packages
  /// that arrive after startup are shown immediately.
  final Future<void> Function(String url)? preloadIcon;

  /// How long a package that left the catalog stays listed, marked in
  /// [departingIds], so the list can fade it out before it is removed.
  final Duration departDuration;

  /// The background refresh started by [load] when a cached catalog was shown.
  /// Completes when it finished; never fails (errors are reported).
  Future<void>? revalidation;

  bool _disposed = false;
  Set<String> _departing = const {};

  List<SoftwarePackage> _packages = const [];
  String? _selectedId;
  AppSettings _settings = const AppSettings();
  bool _isRefreshing = false;
  Object? _loadError;

  List<SoftwarePackage> get packages => _packages;

  /// Packages the catalog no longer lists, still shown while they fade out.
  Set<String> get departingIds => _departing;

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
    final cached = await _useCases.cachedPackages();
    if (cached != null && cached.isNotEmpty) {
      // Show the last known catalog at once; the network catches up behind it.
      _packages = cached;
      _select(preferredId);
      notifyListeners();
      revalidation = _revalidate();
      return;
    }
    try {
      _packages = await _useCases.listPackages();
      onCatalogSynced?.call();
    } on CatalogUnavailable catch (e) {
      _loadError = e;
      _packages = const [];
    }
    _select(preferredId);
    notifyListeners();
  }

  void _select(String? preferredId) {
    _selectedId = _packages.any((p) => p.id == preferredId)
        ? preferredId
        : _packages.firstOrNull?.id;
  }

  /// Brings the shown catalog up to date in three visible steps: text first,
  /// then new packages (each once its icon is ready), then changed icons.
  Future<void> _revalidate() async {
    try {
      await _useCases.refreshCatalog();
      final plan = reconcileCatalog(_packages, await _useCases.listPackages());
      if (_disposed) return;

      await _applyText(plan);
      if (_disposed) return;

      await Future.wait([
        for (final p in plan.added) _arrive(p, plan.order),
        for (final p in plan.iconChanged) _swapIcon(p),
      ]);
      if (!_disposed) onCatalogSynced?.call();
    } catch (error, stack) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'hub catalog refresh',
        ),
      );
    }
  }

  /// Swaps the text in place. Packages that left the catalog stay for
  /// [departDuration], marked as departing, then go; if the selected one is
  /// among them the selection moves to its neighbour, not back to the top.
  Future<void> _applyText(CatalogReconciliation plan) async {
    final updated = {for (final p in plan.textUpdated) p.id: p};
    final leaving = {
      for (final p in _packages)
        if (!updated.containsKey(p.id)) p.id,
    };
    _packages = [for (final p in _packages) updated[p.id] ?? p];
    _departing = leaving;
    notifyListeners();
    if (leaving.isEmpty) return;

    await Future<void>.delayed(departDuration);
    if (_disposed) return;
    final oldIndex = _packages.indexWhere((p) => p.id == _selectedId);
    final remaining = [
      for (final p in _packages)
        if (!leaving.contains(p.id)) p,
    ];
    if (leaving.contains(_selectedId)) {
      final after = _packages
          .skip(oldIndex + 1)
          .where((p) => !leaving.contains(p.id));
      final before = _packages
          .take(oldIndex)
          .toList()
          .reversed
          .where((p) => !leaving.contains(p.id));
      _selectedId = (after.firstOrNull ?? before.firstOrNull)?.id;
    }
    _packages = remaining;
    _departing = const {};
    notifyListeners();
  }

  Future<void> _ready(String? url) async {
    if (url != null) await preloadIcon?.call(url);
  }

  Future<void> _arrive(SoftwarePackage package, List<String> order) async {
    await _ready(package.iconUrl);
    if (_disposed) return;
    _packages = [..._packages, package]
      ..sort((a, b) => order.indexOf(a.id).compareTo(order.indexOf(b.id)));
    _selectedId ??= package.id;
    notifyListeners();
  }

  Future<void> _swapIcon(SoftwarePackage fresh) async {
    await _ready(fresh.iconUrl);
    if (_disposed) return;
    _packages = [
      for (final p in _packages)
        p.id == fresh.id ? p.copyWith(iconUrl: fresh.iconUrl) : p,
    ];
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
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
