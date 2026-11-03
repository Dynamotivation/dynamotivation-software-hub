import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../application/errors.dart';
import '../application/self_update.dart';

/// Downloads the body of [uri] into [destination], returning the number of
/// bytes written and reporting progress with the total size, when the server
/// carries a `Content-Length`. Test doubles replace the whole thing.
typedef SetupDownload =
    Future<int> Function(
      Uri uri,
      IOSink destination, {
      void Function(int bytes, int? total)? onProgress,
    });

/// The staging name of a setup.
String stagedSetupName(String version) {
  final safe = version.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-');
  return 'setup-$safe.exe';
}

/// The file name at the tail of [p], whatever separator the caller built it
/// with (dart:io paths accept both on Windows).
String fileNameOf(String p) {
  final cut = [
    p.lastIndexOf(Platform.pathSeparator),
    p.lastIndexOf(r'\'),
    p.lastIndexOf('/'),
  ].reduce((a, b) => a > b ? a : b);
  return cut < 0 ? p : p.substring(cut + 1);
}

/// The staging folder name, below the hub's own cache directory (not the
/// OS temp directory that Windows sweeps). The uninstaller removes the whole
/// cache folder.
const _updatesFolderName = 'updates';

/// Runs the hub's own updates with the real installer. Staged setups live
/// in the hub's own cache:
/// `%LOCALAPPDATA%\Dynamotivation Software Hub\Cache\updates`.
class StagedSetupInstaller implements SetupInstaller {
  final Directory cache;
  final SetupDownload _download;

  /// [cache] is the app's cache folder, `cacheDirectory(app)` as the apps
  /// already wire it. A null [download] means the plain HTTP transport.
  StagedSetupInstaller(this.cache, {SetupDownload? download})
    : _download = download ?? httpDownloadSetup;

  Directory get _updatesDir =>
      Directory('${cache.path}${Platform.pathSeparator}$_updatesFolderName');

  File _staged(String name) =>
      File('${_updatesDir.path}${Platform.pathSeparator}$name');

  @override
  Future<String> stage(
    SelfUpdateOffer offer, {
    void Function(double progress)? onProgress,
  }) async {
    final link = offer.setup;
    final uri = Uri.tryParse(link.url);
    if (uri == null || uri.scheme.isEmpty) {
      throw SetupUnavailable(
        Uri.tryParse(link.url) ?? Uri(),
        'Download url is not a URI: ${link.url}',
      );
    }
    if (link.sha256.toLowerCase().length != sha256HashLength) {
      throw SetupUnavailable(uri, 'The catalog carries no 64-hex sha256.');
    }
    await _updatesDir.create(recursive: true);
    final name = stagedSetupName(offer.version);
    await _removeStaleExcept(keepName: name);

    // A setup staged earlier (downloaded in the background, not installed
    // yet) is reused while it is still the file the catalog promises.
    final existing = _staged(name);
    if (await existing.exists() &&
        await _digestOf(existing) == link.sha256.toLowerCase()) {
      onProgress?.call(1.0);
      return existing.path;
    }
    final tmp = _staged('$name.part');
    int written;
    try {
      final sink = tmp.openWrite();
      try {
        written = await _download(
          uri,
          sink,
          onProgress: (bytes, total) {
            final size = total ?? (link.size > 0 ? link.size : null);
            if (size != null && onProgress != null) {
              onProgress((bytes / size).clamp(0.0, 1.0));
            }
          },
        );
      } finally {
        await sink.flush();
        await sink.close();
      }
    } catch (error, stack) {
      await _deleteIgnoringFailure(tmp);
      Error.throwWithStackTrace(
        SetupUnavailable(uri, 'Download failed: $error'),
        stack,
      );
    }

    if (link.size > 0 && written != link.size) {
      await _deleteIgnoringFailure(tmp);
      throw SetupUnavailable(uri, 'Got $written bytes, expected ${link.size}.');
    }
    final actual = await _digestOf(tmp);
    if (actual != link.sha256.toLowerCase()) {
      await _deleteIgnoringFailure(tmp);
      throw SetupUnavailable(
        uri,
        'sha256 mismatch: got $actual, want ${link.sha256.toLowerCase()}.',
      );
    }
    final target = _staged(name);
    // A previous staging of the same version may still sit there; rename
    // does not overwrite an existing file on Windows.
    await _deleteIgnoringFailure(target);
    try {
      await tmp.rename(target.path);
    } on FileSystemException catch (e) {
      throw SetupUnavailable(uri, 'Staging failed: ${e.message}');
    }
    if (onProgress != null) onProgress(1.0);
    return target.path;
  }

  /// The apply script is the only moving part: it runs the setup silently
  /// (the app has quit by then, so no file is locked), removes the setup,
  /// and with [restart] opens the hub again. Installer scripts stay free of
  /// code this way, the same for every app.
  @override
  Future<void> install(String stagedFile, {required bool restart}) async {
    if (!Platform.isWindows) {
      throw SetupLaunchFailed(
        stagedFile,
        'Running a staged setup only exists on Windows.',
      );
    }
    final file = File(stagedFile);
    if (!await file.exists()) {
      throw SetupLaunchFailed(stagedFile, 'The staged setup is gone.');
    }
    final script = _staged(_applyScriptName);
    try {
      await script.writeAsString(
        applyScript(
          setup: file.path,
          app: restart ? Platform.resolvedExecutable : null,
        ),
      );
      await Process.start(
        'cmd.exe',
        ['/d', '/c', script.path],
        mode: ProcessStartMode.detached,
      );
    } on FileSystemException catch (e) {
      throw SetupLaunchFailed(stagedFile, e.message);
    } on ProcessException catch (e) {
      throw SetupLaunchFailed(stagedFile, e.message);
    }
  }

  @override
  Future<void> clearStaged({String? keep}) async {
    if (!await _updatesDir.exists()) return;
    await _removeStaleExcept(keepName: keep == null ? null : fileNameOf(keep));
  }

  /// Deletes every staged setup (`setup-*.exe`) and interrupted download
  /// (`.part`) other than the one to [keepName].
  Future<void> _removeStaleExcept({String? keepName}) async {
    final entries = await _updatesDir.list().toList();
    for (final entry in entries) {
      if (entry is! File) continue;
      final name = fileNameOf(entry.path);
      final stale =
          (name.startsWith('setup-') && name.endsWith('.exe') && name != keepName) ||
          name.endsWith('.part') ||
          name == _applyScriptName;
      if (stale) {
        await _deleteIgnoringFailure(entry);
      }
    }
  }

  Future<String> _digestOf(File file) async {
    final bytes = await file.readAsBytes();
    return sha256.convert(bytes).toString();
  }
  /// Deleting a stale file never blocks the update that is happening now:
  /// a locked or missing one is no reason to stop the install.
  Future<void> _deleteIgnoringFailure(File file) async {
    try {
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // Gone next time; the installer will clean it too.
    }
  }
}

const _applyScriptName = 'apply.cmd';

/// The batch file that runs [setup] silently, deletes it, and, given [app],
/// starts the hub again. Quoted paths survive spaces; `start ""` detaches.
String applyScript({required String setup, String? app}) => [
  '@echo off',
  '"$setup" /VERYSILENT /SUPPRESSMSGBOXES /NORESTART',
  'del /f /q "$setup"',
  if (app != null) 'start "" "$app"',
  '',
].join('\r\n');

/// Length of a hexadecimal SHA-256 digest.
const sha256HashLength = 64;

/// Streams [uri] into [destination]. Progress comes from the response's
/// `Content-Length`, when the server carries one. Failures reach [stage],
/// which wraps them in [SetupUnavailable].
Future<int> httpDownloadSetup(
  Uri uri,
  IOSink destination, {
  void Function(int bytes, int? total)? onProgress,
}) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    if (response.statusCode != HttpStatus.ok) {
      throw SetupUnavailable(
        uri,
        'The setup answered HTTP ${response.statusCode}.',
      );
    }
    final total = response.contentLength >= 0 ? response.contentLength : null;
    var bytes = 0;
    await for (final chunk in response) {
      bytes += chunk.length;
      if (onProgress != null) onProgress(bytes, total);
      destination.add(chunk);
    }
    return bytes;
  } finally {
    client.close(force: true);
  }
}
