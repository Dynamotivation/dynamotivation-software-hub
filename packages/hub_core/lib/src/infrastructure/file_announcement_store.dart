import 'dart:convert';
import 'dart:io';

import '../application/announcement_store.dart';
import '../domain/software_version.dart';

/// [AnnouncementStore] in one JSON file inside the app's cache folder:
/// `{"announced": {"<package id>": "<last announced version>"}}`.
///
/// Older builds stored a list of versions per package; reading such a file
/// keeps the newest of them, so nothing is announced twice after the switch.
///
/// Reading is forgiving: a missing, unreadable or malformed file is "nothing
/// stored", which settles a silent baseline rather than a flood of
/// announcements. Writing is atomic (temp file, then rename) and its failures
/// reach the caller.
class FileAnnouncementStore implements AnnouncementStore {
  FileAnnouncementStore(Directory cache)
    : _file = File('${cache.path}${Platform.pathSeparator}announced.json');

  final File _file;

  @override
  Future<Announced?> load() async {
    try {
      if (!await _file.exists()) return null;
      final json = jsonDecode(await _file.readAsString());
      if (json is! Map<String, dynamic>) return null;
      final raw = json['announced'];
      if (raw is! Map<String, dynamic>) return null;
      return {for (final e in raw.entries) e.key: ?_lastVersion(e.value)};
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  @override
  Future<void> save(Announced announced) async {
    await _file.parent.create(recursive: true);
    final temp = File('${_file.path}.tmp');
    await temp.writeAsString(
      jsonEncode({
        'announced': {
          for (final e in announced.entries)
            if (e.value.isNotEmpty) e.key: e.value,
        },
      }),
      flush: true,
    );
    await temp.rename(_file.path);
  }

  /// The version a stored value stands for: the string itself, or the newest
  /// of a legacy list. Empty versions (a package listed before its first
  /// release) are dropped; null means nothing usable.
  static String? _lastVersion(Object? value) {
    if (value is String) return value.isEmpty ? null : value;
    if (value is! List) return null;
    String? newest;
    for (final item in value) {
      final version = item.toString();
      if (version.isEmpty) continue;
      if (newest == null || isNewerSoftwareVersion(version, newest)) {
        newest = version;
      }
    }
    return newest;
  }
}
