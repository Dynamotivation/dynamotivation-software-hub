import '../domain/software_package.dart';
import '../domain/software_version.dart';
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

/// Whether [candidate] is ahead of the [last] version the user knows. Only a
/// newer version is ahead: a lower one is never announced. Versions that
/// cannot be ordered (not parseable) count as ahead when they differ, since
/// nothing better can be said.
bool _isAhead(String candidate, String last) {
  if (isNewerSoftwareVersion(candidate, last)) return true;
  if (isNewerSoftwareVersion(last, candidate)) return false;
  return !isSameSoftwareVersion(last, candidate);
}

/// What of [catalog] the user was not told about yet. This is the one place
/// that decides what counts as known:
///  - No release yet (empty version): not reported, not remembered. There is
///    nothing to try, and the first release later is new software.
///  - No stored version: **new software**.
///  - A newest version that is newer than the stored one: an **update**. A
///    lower or equal version is never reported, so a published version that
///    moves back down, or flips back and forth, stays silent.
/// Entries that disappeared are not reported; they vanish from the website
/// without a user-facing trail worth announcing.
CatalogUpdates unannouncedUpdates(
  List<SoftwarePackage> catalog,
  Announced announced,
) {
  final newPackages = <SoftwarePackage>[];
  final versionUpdates = <SoftwarePackage>[];
  for (final p in catalog) {
    if (p.latestVersion.isEmpty) continue;
    final last = announced[p.id];
    if (last == null || last.isEmpty) {
      newPackages.add(p);
    } else if (_isAhead(p.latestVersion, last)) {
      versionUpdates.add(p);
    }
  }
  return CatalogUpdates(
    newPackages: newPackages,
    versionUpdates: versionUpdates,
  );
}

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
      if (catalog.isNotEmpty) await _record(catalog);
      return const CatalogUpdates();
    }
    return unannouncedUpdates(catalog, announced);
  }

  /// The only writer of the stored state: records the newest version of each
  /// of [packages] as the last one the user knows. The stored version only
  /// ever moves up, so a catalog that briefly shows a lower one cannot make
  /// the higher one look new again. Packages without a release are skipped, or
  /// the software would later look known and its first release like a mere
  /// update.
  Future<void> _record(List<SoftwarePackage> packages) async {
    final next = {...?_announced};
    for (final p in packages) {
      if (p.latestVersion.isEmpty) continue;
      final last = next[p.id];
      if (last == null || last.isEmpty || _isAhead(p.latestVersion, last)) {
        next[p.id] = p.latestVersion;
      }
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

  /// Records that the user was *told* about [updates] (a notification was
  /// delivered, or notifications are off). Call it only after delivery, so a
  /// failed delivery is retried by the next check.
  Future<void> markAnnounced(CatalogUpdates updates) => _serial(() async {
    if (updates.isEmpty) return;
    await _state();
    await _record(updates.packages);
  });

  /// Records that the user *saw* the whole current catalog on screen, without
  /// reporting anything. The frontend calls this after a load or a manual
  /// refresh, so the next check does not announce what was already visible.
  Future<void> markSeen() => _serial(() async {
    await _state();
    final catalog = await _useCases.listPackages();
    if (catalog.isEmpty && _announced == null) return;
    await _record(catalog);
  });
}
