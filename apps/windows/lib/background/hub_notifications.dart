import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications_windows/flutter_local_notifications_windows.dart';

/// The identity Windows files the hub's toasts under. It is registered per
/// user (HKCU) by the plugin the first time the app starts, and removed again
/// by the uninstaller (`[Registry]` in `installer-toolkit/setup/software-hub.iss`),
/// so the two must stay in step.
const hubAppUserModelId = 'Dynamotivation.SoftwareHub';

/// Class id of the in-process click handler, written beside the identity.
const hubNotificationGuid = '3d6f1a52-8c47-4b0e-9a1d-5e2c7f4b8a90';

/// The background toast notifications, shown when a catalog change comes in
/// while the hub window is hidden in the tray or visible on screen alike:
/// the OS notification system is the surface in both states. Windows only.
class HubNotifications {
  HubNotifications({required this.onNotificationClicked});

  /// Called when the user clicks a toast: a click wants to see the hub.
  final void Function() onNotificationClicked;

  FlutterLocalNotificationsWindows? _plugin;
  int _nextId = 1;

  /// Registers the app identity with Windows once. Must run before the
  /// first [show]; calling it again is harmless. Does nothing off Windows.
  Future<void> setup(String appName) async {
    if (!Platform.isWindows || _plugin != null) return;
    final plugin = FlutterLocalNotificationsWindows();
    final ready = await plugin.initialize(
      settings: WindowsInitializationSettings(
        appName: appName,
        appUserModelId: hubAppUserModelId,
        guid: hubNotificationGuid,
        iconPath: _headerIconPath(),
      ),
      // Any click, and any action, wants to see the hub.
      onDidReceiveNotificationResponse: (_) => Timer.run(onNotificationClicked),
    );
    if (!ready) {
      throw StateError('Windows refused the notification registration.');
    }
    _plugin = plugin;
  }

  /// The small icon in the toast header: the bundled brand mark, next to the
  /// exe (debug runs have the same `data/flutter_assets` folder).
  static String _headerIconPath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir/data/flutter_assets/assets/notification_icon.png'
        .replaceAll('/', r'\');
  }

  /// [imagePath] is a PNG or JPEG shown at the left of the toast, in place
  /// of the header icon's slot, e.g. the icon of the software it is about.
  Future<void> show({
    required String title,
    required String body,
    String? imagePath,
  }) async {
    final plugin = _plugin;
    if (plugin == null) return;
    await plugin.show(
      id: _nextId++,
      title: title,
      body: body,
      notificationDetails: WindowsNotificationDetails(
        images: [
          if (imagePath != null)
            WindowsImage(
              Uri.file(imagePath, windows: true),
              altText: title,
              placement: WindowsImagePlacement.appLogoOverride,
            ),
        ],
      ),
    );
  }
}

/// Reports a failed background notification exactly like other background
/// probes: not hidden, but not blocking the UI either.
void reportBackgroundError(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(exception: error, stack: stackTrace),
  );
}
