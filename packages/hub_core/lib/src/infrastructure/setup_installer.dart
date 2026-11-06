import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../application/errors.dart';
import '../application/self_update.dart';

/// Downloads the body of [uri] into [destination], returning the number of
/// bytes written and reporting progress with the total size, when the server
/// carries a `Content-Length`. Test doubles replace the whole thing.
typedef SetupDownload = Future<int> Function(
  Uri uri,
  IOSink destination, {
  void Function(int bytes, int? total)? onProgress,
});

/// Starts a setup process; tests replace it.
typedef SetupProcessStart = Future<Process> Function(
  String executable,
  List<String> arguments,
);

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
  final SetupProcessStart _start;

  /// [cache] is the app's cache folder, `cacheDirectory(app)` as the apps
  /// already wire it. A null [download] means the plain HTTP transport.
  StagedSetupInstaller(
    this.cache, {
    SetupDownload? download,
    SetupProcessStart? start,
  }) : _download = download ?? httpDownloadSetup,
       _start = start ?? Process.start;

  Directory get _updatesDir =>
      Directory('${cache.path}${Platform.pathSeparator}$_updatesFolderName');

  File _staged(String name) => _in(_updatesDir, name);

  File _in(Directory dir, String name) =>
      File('${dir.path}${Platform.pathSeparator}$name');

  /// The hub's own update stages directly in `updates`; every other
  /// package in its own subfolder, so cleaning one never touches another.
  Directory _folderOf(String packageId) => packageId == hubPackageId
      ? _updatesDir
      : Directory(
          '${_updatesDir.path}${Platform.pathSeparator}'
          '${packageId.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '-')}',
        );

  @override
  Future<String> stage(
    SetupOffer offer, {
    void Function(double progress)? onProgress,
  }) async {
    final dir = _folderOf(offer.packageId);
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
    await dir.create(recursive: true);
    final name = stagedSetupName(offer.version);
    await _removeStaleExcept(dir, keepName: name);

    // A setup staged earlier (downloaded in the background, not installed
    // yet) is reused while it is still the file the catalog promises.
    final existing = _in(dir, name);
    if (await existing.exists() &&
        await _digestOf(existing) == link.sha256.toLowerCase()) {
      onProgress?.call(1.0);
      return existing.path;
    }
    final tmp = _in(dir, '$name.part');
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
    final target = _in(dir, name);
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
      await Process.start('cmd.exe', [
        '/d',
        '/c',
        script.path,
      ], mode: ProcessStartMode.detached);
    } on FileSystemException catch (e) {
      throw SetupLaunchFailed(stagedFile, e.message);
    } on ProcessException catch (e) {
      throw SetupLaunchFailed(stagedFile, e.message);
    }
  }

  @override
  Future<void> clearStaged({String? keep}) async {
    if (!await _updatesDir.exists()) return;
    await _removeStaleExcept(
      _updatesDir,
      keepName: keep == null ? null : fileNameOf(keep),
    );
    // Package folders left empty by an earlier install are not kept around.
    await for (final entry in _updatesDir.list()) {
      if (entry is Directory) await _removeIfEmpty(entry);
    }
  }

  @override
  Future<int> run(String stagedFile, {required String logFile}) async {
    if (!Platform.isWindows) {
      throw SetupLaunchFailed(stagedFile, 'Setups only run on Windows.');
    }
    if (!await File(stagedFile).exists()) {
      throw SetupLaunchFailed(stagedFile, 'The staged setup is gone.');
    }
    try {
      final process = await _start(stagedFile, [
        ...silentSetupArguments,
        '/LOG=$logFile',
      ]);
      return await process.exitCode;
    } on ProcessException catch (e) {
      throw SetupLaunchFailed(stagedFile, e.message);
    }
  }

  @override
  Future<int> uninstall(String uninstaller, {required String logFile}) async {
    if (!Platform.isWindows) {
      throw SetupLaunchFailed(uninstaller, 'Uninstallers only run on Windows.');
    }
    if (!await File(uninstaller).exists()) {
      throw SetupLaunchFailed(uninstaller, 'The uninstaller is gone.');
    }
    try {
      final process = await _start(uninstaller, [
        ...silentUninstallArguments,
        '/LOG=$logFile',
      ]);
      return await process.exitCode;
    } on ProcessException catch (e) {
      throw SetupLaunchFailed(uninstaller, e.message);
    }
  }

  @override
  Future<void> discard(String stagedFile) async {
    final file = File(stagedFile);
    await _deleteIgnoringFailure(file);
    // A package's own staging folder goes with its last setup; the shared
    // `updates` folder stays for the hub's own update.
    if (file.parent.absolute.path != _updatesDir.absolute.path) {
      await _removeIfEmpty(file.parent);
    }
  }

  /// Deletes [dir] if nothing is left in it; a folder still in use stays.
  Future<void> _removeIfEmpty(Directory dir) async {
    try {
      if (await dir.exists() && await dir.list().isEmpty) await dir.delete();
    } on FileSystemException {
      // Locked or refilled meanwhile: it is cleaned on a later start.
    }
  }

  /// Deletes every staged setup (`setup-*.exe`) and interrupted download
  /// (`.part`) other than the one to [keepName].
  Future<void> _removeStaleExcept(Directory dir, {String? keepName}) async {
    final entries = await dir.list().toList();
    for (final entry in entries) {
      if (entry is! File) continue;
      final name = fileNameOf(entry.path);
      final stale =
          (name.startsWith('setup-') &&
              name.endsWith('.exe') &&
              name != keepName) ||
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

/// How the Hub runs the setup of any app: no wizard, no message boxes, no
/// restart, and no desktop icon. `/MERGETASKS` only switches the named task
/// off; every other task keeps its default, so an app's required tasks (a
/// runtime prerequisite) still run.
const silentSetupArguments = [
  '/VERYSILENT',
  '/SUPPRESSMSGBOXES',
  '/NORESTART',
  '/MERGETASKS=!desktopicon',
];

/// How the Hub runs an app's Inno uninstaller: no questions, no message
/// boxes, no restart.
const silentUninstallArguments = [
  '/VERYSILENT',
  '/SUPPRESSMSGBOXES',
  '/NORESTART',
];

/// The batch file that runs [setup] silently, deletes it, and, given [app],
/// starts the hub again. Quoted paths survive spaces; `start ""` detaches.
String applyScript({required String setup, String? app}) => [
  '@echo off',
  '"$setup" ${silentSetupArguments.join(' ')}',
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
