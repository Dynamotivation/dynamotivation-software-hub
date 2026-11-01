import 'dart:async';

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
    await localNotifier.setup(appName: appName);

    if (_listener == null) {
      _listener = _NotificationClickForwarder(onNotificationClicked);
      localNotifier.addListener(_listener!);
    }
  }

  Future<void> show({required String title, required String body}) async {
    await localNotifier.notify(LocalNotification(title: title, body: body));
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
