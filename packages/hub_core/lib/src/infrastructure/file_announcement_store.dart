import 'dart:convert';
import 'dart:io';

import '../application/announcement_store.dart';

/// [AnnouncementStore] in one JSON file inside the app's cache folder:
/// `{"announced": {"<package id>": ["<version>", ...]}}`.
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
      return {
        for (final e in raw.entries)
          if (e.value is List)
            e.key: {for (final v in e.value as List) v.toString()},
      };
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
          for (final e in announced.entries) e.key: e.value.toList()..sort(),
        },
      }),
      flush: true,
    );
    await temp.rename(_file.path);
  }
}
