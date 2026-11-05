import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../application/errors.dart';
import '../application/installed_application_repository.dart';
import '../domain/installed_application.dart';

/// Reads current-user and machine uninstall registrations in both registry
/// views. No elevation, WMI product queries, or execution of uninstall strings.
class WindowsInstalledApplicationRepository
    implements InstalledApplicationRepository {
  final Future<String> Function() _read;

  WindowsInstalledApplicationRepository({Future<String> Function()? read})
    : _read = read ?? readRegistry;

  @override
  Future<List<InstalledApplication>> scan() async {
    try {
      return parse(await _read());
    } on InstalledSoftwareUnavailable {
      rethrow;
    } catch (error) {
      throw InstalledSoftwareUnavailable(error.toString());
    }
  }

  static List<InstalledApplication> parse(String body) {
    final root = jsonDecode(body);
    if (root is! List) throw const FormatException('Expected registry array');
    final apps = <String, InstalledApplication>{};
    for (final entry in root) {
      if (entry is! Map) throw const FormatException('Invalid registry entry');
      String text(String key) => (entry[key] as String? ?? '').trim();
      if (text('Publisher').toLowerCase() != 'dynamotivation') continue;
      final key = text('Key').toLowerCase();
      final name = text('DisplayName');
      if (key.isEmpty || name.isEmpty) continue;
      if (key == '{6f0b3e52-2c58-4c0b-9f5e-1d7a4b8e9c31}_is1' ||
          name.toLowerCase() == 'dynamotivation software hub') {
        continue;
      }
      // HKCU is emitted first: the user's installation wins over an identical
      // machine-wide registration. Shared HKCU views are deduplicated too.
      apps.putIfAbsent(
        key,
        () => InstalledApplication(
          id: key,
          name: name,
          version: text('DisplayVersion'),
          launchExecutable: executableFromDisplayIcon(text('DisplayIcon')),
        ),
      );
    }
    return apps.values.toList();
  }

  /// Inno registers the main EXE as its uninstall display icon. Accept a
  /// filename with an optional icon index, never a command line or DLL/ICO.
  static String executableFromDisplayIcon(String value) {
    final match = RegExp(
      r'^\s*(?:"([^"\r\n]+\.exe)"|([^"\r\n]+\.exe))(?:\s*,\s*-?\d+)?\s*$',
      caseSensitive: false,
    ).firstMatch(value);
    final executable = (match?[1] ?? match?[2] ?? '').trim();
    final windows = path.Context(style: path.Style.windows);
    if (!windows.isAbsolute(executable)) return '';
    final name = windows.basename(executable).toLowerCase();
    if (RegExp(r'^unins\d*\.exe$').hasMatch(name) || name == 'uninstall.exe') {
      return '';
    }
    return executable;
  }

  static Future<String> readRegistry() async {
    final windows = Platform.environment['SystemRoot'] ?? r'C:\Windows';
    final result = await Process.run(
      '$windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe',
      ['-NoLogo', '-NoProfile', '-NonInteractive', '-Command', registryScript],
      stdoutEncoding: utf8,
      stderrEncoding: utf8,
    );
    if (result.exitCode != 0) {
      throw InstalledSoftwareUnavailable('Registry scan: ${result.stderr}');
    }
    return result.stdout as String;
  }

  /// Fixed script; no registry content is interpolated into executable code.
  static const registryScript = r'''
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)
$items = @(
  foreach ($hive in @('CurrentUser', 'LocalMachine')) {
    foreach ($view in @('Registry64', 'Registry32')) {
      $base = [Microsoft.Win32.RegistryKey]::OpenBaseKey($hive, $view)
      try {
        $root = $base.OpenSubKey('Software\Microsoft\Windows\CurrentVersion\Uninstall')
        if ($null -eq $root) { continue }
        try {
          foreach ($name in $root.GetSubKeyNames()) {
            $key = $root.OpenSubKey($name)
            if ($null -eq $key) { continue }
            try {
              if ($key.GetValue('Publisher') -ne 'Dynamotivation') { continue }
              [PSCustomObject]@{
                Key = $name
                Publisher = [string]$key.GetValue('Publisher')
                DisplayName = [string]$key.GetValue('DisplayName')
                DisplayVersion = [string]$key.GetValue('DisplayVersion')
                DisplayIcon = [string]$key.GetValue('DisplayIcon')
              }
            } finally { $key.Dispose() }
          }
        } finally { $root.Dispose() }
      } finally { $base.Dispose() }
    }
  }
)
ConvertTo-Json -InputObject $items -Compress
''';
}
