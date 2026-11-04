import '../domain/software_package.dart';
import 'announcement_store.dart';
import 'hub_use_cases.dart';

/// What the catalog offers that the user has not been told about yet.
class CatalogUpdates {
  /// Entries the user has never been told about. Empty when none.
  final List<SoftwarePackage> newPackages;

  /// Entries the user knows, whose newest release version is one they have
  /// not been told about. Versions are unique per release, so any new
  /// version counts, even a correction that moved the published version
  /// downwards.
  final List<SoftwarePackage> versionUpdates;

  const CatalogUpdates({
    this.newPackages = const [],
    this.versionUpdates = const [],
  });

  bool get isEmpty => newPackages.isEmpty && versionUpdates.isEmpty;

  /// How many different software entries are affected.
  int get count => newPackages.length + versionUpdates.length;

  /// Every affected entry, new ones first.
  List<SoftwarePackage> get packages => [...newPackages, ...versionUpdates];
}

/// What of [catalog] is not in [announced] yet: ids never announced are new,
/// known ids with an unannounced newest version are updates. Entries that
/// disappeared are not reported; they vanish from the website without a
/// user-facing trail worth announcing.
CatalogUpdates unannouncedUpdates(
  List<SoftwarePackage> catalog,
  Announced announced,
) => CatalogUpdates(
  newPackages: [
    for (final p in catalog)
      if (!announced.containsKey(p.id)) p,
  ],
  versionUpdates: [
    for (final p in catalog)
      if (announced[p.id] case final versions?
          when !versions.contains(p.latestVersion))
        p,
  ],
);

/// Finds what is new in the catalog since the user was last told, and
/// remembers what was told.
///
/// The memory is an [AnnouncementStore], so it survives restarts: relaunching
/// the app (including the restart after a self-update) announces only what
/// the user has not been told about. The very first run, with nothing stored,
/// settles the current catalog as the baseline and announces nothing; so does
/// a stored state that cannot be read. Watching only reports; callers decide
/// how to tell the user and then call [markAnnounced].
///
/// The hub's own entry is not part of the catalog the watcher sees
/// ([HubUseCases.listPackages]), so the app updating itself is never an
/// announcement.
class CatalogUpdateWatcher {
  CatalogUpdateWatcher(this._useCases, {AnnouncementStore? store})
    : _store = store ?? InMemoryAnnouncementStore();

  final HubUseCases _useCases;
  final AnnouncementStore _store;

  Announced? _announced;
  Future<void> _tail = Future.value();

  /// Runs [operation] after every earlier one, so concurrent callers
  /// (startup check, hourly poll, manual refresh) cannot interleave their
  /// reads and writes of the stored state.
  Future<T> _serial<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  Future<Announced?> _state() async => _announced ??= await _store.load();

  /// Reports what [catalog] holds beyond the stored state; settles a silent
  /// baseline when nothing was stored yet.
  Future<CatalogUpdates> _evaluate(List<SoftwarePackage> catalog) async {
    final announced = await _state();
    if (announced == null) {
      // An empty catalog says nothing: wait for a real one to settle on.
      if (catalog.isNotEmpty) await _remember(catalog);
      return const CatalogUpdates();
    }
    return unannouncedUpdates(catalog, announced);
  }

  Future<void> _remember(List<SoftwarePackage> packages) async {
    final next = <String, Set<String>>{
      for (final e in (_announced ?? const <String, Set<String>>{}).entries)
        e.key: {...e.value},
    };
    for (final p in packages) {
      (next[p.id] ??= {}).add(p.latestVersion);
    }
    await _store.save(next);
    _announced = next;
  }

  /// One scheduled check: fetches the catalog from its source and reports
  /// what the user has not been told about. Throws [CatalogUnavailable]
  /// when the catalog cannot be fetched or parsed; nothing changes then.
  Future<CatalogUpdates> poll() => _serial(() async {
    await _useCases.refreshCatalog();
    return _evaluate(await _useCases.listPackages());
  });

  /// Like [poll] for the catalog the app already holds, without fetching:
  /// the startup check after the window loaded.
  Future<CatalogUpdates> pending() =>
      _serial(() async => _evaluate(await _useCases.listPackages()));

  /// Records that the user was told about [updates].
  Future<void> markAnnounced(CatalogUpdates updates) => _serial(() async {
    if (updates.isEmpty) return;
    await _state();
    await _remember(updates.packages);
  });

  /// Records the whole current catalog as known without reporting anything.
  /// The frontend calls this after the user saw a manual refresh in the
  /// window, so the next check does not announce what was on screen.
  Future<void> markSeen() => _serial(() async {
    await _state();
    final catalog = await _useCases.listPackages();
    if (catalog.isEmpty && _announced == null) return;
    await _remember(catalog);
  });
}
