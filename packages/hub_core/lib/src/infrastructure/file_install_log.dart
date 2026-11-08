import 'dart:convert';
import 'dart:io';

import '../application/package_setup.dart';

/// Install records as plain text files in the hub's own folder, next to its
/// cache: `%LOCALAPPDATA%\Dynamotivation Software Hub\Logs` on Windows.
/// One file per install, named by time, package and version; the setup's
/// own log is appended to it when the install ends. Only the newest
/// [keep] files stay.
class FileInstallLog implements InstallLog {
  final Directory directory;
  final int keep;
  final DateTime Function() _now;

  FileInstallLog(this.directory, {this.keep = 50, DateTime Function()? now})
    : _now = now ?? DateTime.now;

  @override
  Future<InstallLogSession> start(String packageId, String version) async {
    await directory.create(recursive: true);
    await _prune();
    final stamp = _now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    final base = _safe('$stamp-$packageId-$version');
    final sep = Platform.pathSeparator;
    return _FileSession(
      File('${directory.path}$sep$base.log'),
      '${directory.path}$sep$base.setup.log',
      _now,
    );
  }

  Future<void> _prune() async {
    final logs = [
      for (final e in await directory.list().toList())
        if (e is File &&
            e.path.endsWith('.log') &&
            !e.path.endsWith('.setup.log'))
          e,
    ]..sort((a, b) => b.path.compareTo(a.path));
    for (final old in logs.skip(keep - 1)) {
      try {
        await old.delete();
      } on FileSystemException {
        // A locked old log is no reason to block a new install.
      }
    }
  }

  static String _safe(String name) =>
      name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
}

class _FileSession implements InstallLogSession {
  final File _file;
  @override
  final String setupLogPath;
  final DateTime Function() _now;

  _FileSession(this._file, this.setupLogPath, this._now);

  @override
  String get path => _file.path;

  @override
  Future<void> write(String line) => _file.writeAsString(
    '${_now().toIso8601String()}  $line\n',
    mode: FileMode.append,
    flush: true,
  );

  @override
  Future<void> close() async {
    final setupLog = File(setupLogPath);
    if (!await setupLog.exists()) return;
    try {
      final text = utf8.decode(
        await setupLog.readAsBytes(),
        allowMalformed: true,
      );
      await _file.writeAsString(
        '\n--- Setup log ---\n$text',
        mode: FileMode.append,
        flush: true,
      );
      await setupLog.delete();
    } on FileSystemException {
      // The setup log stays beside this one.
    }
  }
}
