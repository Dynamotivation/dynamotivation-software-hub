import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:win32_registry/win32_registry.dart';

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
          uninstallExecutable: uninstallerFromCommand(text('UninstallString')),
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

  /// Inno registers `"<app>\unins000.exe"` as the uninstall command. Only
  /// that absolute Inno uninstaller is accepted; its own arguments are
  /// dropped, the hub passes the silent ones itself.
  static String uninstallerFromCommand(String value) {
    final match = RegExp(
      r'^\s*(?:"([^"\r\n]+\.exe)"|([^"\s]+\.exe))(?:\s+[^\r\n]*)?$',
      caseSensitive: false,
    ).firstMatch(value);
    final executable = (match?[1] ?? match?[2] ?? '').trim();
    final windows = path.Context(style: path.Style.windows);
    if (!windows.isAbsolute(executable)) return '';
    final name = windows.basename(executable).toLowerCase();
    return RegExp(r'^unins\d+\.exe$').hasMatch(name) ? executable : '';
  }

  /// Reads the uninstall registrations in-process (no PowerShell: starting it
  /// alone cost a few hundred milliseconds on every launch). Current-user keys
  /// come first, so the user's installation wins over a machine-wide one; the
  /// 32-bit views are the `WOW6432Node` paths, which also reach them from this
  /// 64-bit process. Only the fixed uninstall path is read.
  static Future<String> readRegistry() async {
    const uninstall = r'Software\Microsoft\Windows\CurrentVersion\Uninstall';
    const uninstall32 =
        r'Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall';
    final items = <Map<String, String>>[];
    try {
      for (final hive in [RegistryHive.currentUser, RegistryHive.localMachine]) {
        for (final base in [uninstall, uninstall32]) {
          items.addAll(_readUninstallKeys(hive, base));
        }
      }
    } catch (error) {
      throw InstalledSoftwareUnavailable('Registry scan: $error');
    }
    return jsonEncode(items);
  }

  static List<Map<String, String>> _readUninstallKeys(
    RegistryHive hive,
    String base,
  ) {
    final RegistryKey root;
    try {
      root = Registry.openPath(hive, path: base);
    } on Exception {
      return const []; // This view has no uninstall key.
    }
    final found = <Map<String, String>>[];
    try {
      for (final name in root.subkeyNames) {
        final RegistryKey key;
        try {
          key = Registry.openPath(hive, path: '$base\\$name');
        } on Exception {
          continue; // Removed or unreadable meanwhile.
        }
        try {
          String text(String value) => key.getStringValue(value) ?? '';
          if (text('Publisher') != 'Dynamotivation') continue;
          found.add({
            'Key': name,
            'Publisher': text('Publisher'),
            'DisplayName': text('DisplayName'),
            'DisplayVersion': text('DisplayVersion'),
            'DisplayIcon': text('DisplayIcon'),
            'UninstallString': text('UninstallString'),
          });
        } finally {
          key.close();
        }
      }
    } finally {
      root.close();
    }
    return found;
  }
}
