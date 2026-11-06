import 'dart:io';

import 'package:path/path.dart' as path;

import '../application/application_launcher.dart';

typedef ApplicationStarter = Future<void> Function(
  String executable,
  String workingDirectory,
);

/// Starts the registered EXE directly, with its own directory as the working
/// directory (required by apps that resolve game assets relative to it).
class WindowsApplicationLauncher implements ApplicationLauncher {
  final ApplicationStarter _start;
  final Future<bool> Function(String) _exists;

  WindowsApplicationLauncher({
    ApplicationStarter? start,
    Future<bool> Function(String)? exists,
  }) : _start = start ?? _startProcess,
       _exists = exists ?? FileSystemEntity.isFile;

  @override
  Future<void> launch(String executable) async {
    final windows = path.Context(style: path.Style.windows);
    if (!windows.isAbsolute(executable) ||
        windows.extension(executable).toLowerCase() != '.exe' ||
        !await _exists(executable)) {
      throw ProcessException(
        executable,
        const [],
        'Executable is missing or invalid.',
      );
    }
    await _start(executable, windows.dirname(executable));
  }

  static Future<void> _startProcess(String executable, String directory) async {
    await Process.start(
      executable,
      const [],
      workingDirectory: directory,
      mode: ProcessStartMode.detached,
      runInShell: false,
    );
  }
}
