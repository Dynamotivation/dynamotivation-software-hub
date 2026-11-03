import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:local_notifier/local_notifier.dart';

/// The background toast notifications, shown when a catalog change comes in
/// while the hub window is hidden in the tray or visible on screen alike:
/// the OS notification system is the surface in both states.
class HubNotifications {
  HubNotifications({required this.onNotificationClicked});

  /// Called when the user clicks a toast: a click wants to see the hub.
  final void Function() onNotificationClicked;

  LocalNotificationListener? _listener;

  /// Registers the app identity with Windows once. Must run before the
  /// first [show]; calling it again is harmless.
  Future<void> setup(String appName) async {
    await _dropStaleShortcut(appName);
    await localNotifier.setup(appName: appName);

    if (_listener == null) {
      _listener = _NotificationClickForwarder(onNotificationClicked);
      localNotifier.addListener(_listener!);
    }
  }

  /// The toast's identity (name and small header icon) comes from the Start
  /// menu shortcut the plugin creates for this app. It only creates one if
  /// none exists and never repairs it, so a shortcut left by an older build
  /// keeps pointing at that build's exe and icon. Removing it first lets the
  /// plugin write a fresh one for the exe that is running. Only the plugin's
  /// own top-level `<appName>.lnk` is touched, never the installer's shortcut
  /// in the Dynamotivation folder.
  Future<void> _dropStaleShortcut(String appName) async {
    final programs = Platform.environment['APPDATA'];
    if (!Platform.isWindows || programs == null) return;
    final shortcut = File(
      '$programs/Microsoft/Windows/Start Menu/Programs/$appName.lnk',
    );
    try {
      if (await shortcut.exists()) await shortcut.delete();
    } on FileSystemException catch (error, stack) {
      reportBackgroundError(error, stack);
    }
  }

  /// [imagePath] is a PNG or JPEG file shown with the toast, if any.
  Future<void> show({
    required String title,
    required String body,
    String? imagePath,
  }) async {
    await localNotifier.notify(
      LocalNotification(title: title, body: body, imagePath: imagePath),
    );
  }
}

class _NotificationClickForwarder implements LocalNotificationListener {
  _NotificationClickForwarder(this._onClicked);

  final void Function() _onClicked;

  @override
  void onLocalNotificationShow(LocalNotification notification) {}

  /// Clicking a toast asks to see the hub. Close naturally is not a click
  /// and is ignored so the OS still treats it as read.
  @override
  void onLocalNotificationClick(LocalNotification notification) {
    Timer.run(_onClicked);
  }

  @override
  void onLocalNotificationClickAction(
    LocalNotification notification,
    int actionIndex,
  ) {
    Timer.run(_onClicked);
  }

  @override
  void onLocalNotificationClose(
    LocalNotification notification,
    LocalNotificationCloseReason closeReason,
  ) {}
}

/// Reports a failed background notification exactly like other background
/// probes: not hidden, but not blocking the UI either.
void reportBackgroundError(Object error, StackTrace stackTrace) {
  FlutterError.reportError(
    FlutterErrorDetails(exception: error, stack: stackTrace),
  );
}
