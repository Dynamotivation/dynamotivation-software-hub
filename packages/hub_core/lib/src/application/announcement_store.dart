/// What the hub has already told the user about: per package id, the newest
/// release version the user was told about or saw on screen. Only that one
/// version is kept, and it only ever moves up: a lower version is never
/// announced or recorded. A package without an entry was never announced; no
/// entry ever holds an empty version.
typedef Announced = Map<String, String>;

/// Port for keeping [Announced] across app restarts, so a relaunch does not
/// announce the same catalog again.
abstract interface class AnnouncementStore {
  /// The stored state, or null when nothing was stored yet (first run) or
  /// what is stored cannot be read. Null makes the next evaluation settle a
  /// fresh baseline silently instead of announcing the whole catalog.
  Future<Announced?> load();

  /// Replaces the stored state.
  Future<void> save(Announced announced);
}

/// Keeps the state for the lifetime of the process only. For tests and
/// frontends without a cache folder.
class InMemoryAnnouncementStore implements AnnouncementStore {
  Announced? _state;

  @override
  Future<Announced?> load() async => _state == null ? null : _copy(_state!);

  @override
  Future<void> save(Announced announced) async => _state = _copy(announced);

  static Announced _copy(Announced a) => {...a};
}
