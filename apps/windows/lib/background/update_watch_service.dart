import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hub_core/hub_core.dart';

/// Signature the composition root wires to the OS notification surface.
/// [iconUrl] is the catalog icon of the software the toast is about.
typedef ShowNotification = Future<void> Function({
  required String title,
  required String body,
  String? iconUrl,
});

/// The localized words the watch service needs. [BackgroundStrings]
/// provides the implementation.
abstract class WatchTexts {
  String get newSoftwareTitle;
  String get updateNotificationTitle;
  String newSoftwareBody(String name);
  String updateNotificationBody(String name, String version);
}

/// The scheduled half of background running: about once an hour the catalog
/// is fetched again and every new software entry or newer release is
/// announced. The window being visible makes no difference: the hub shows
/// these notifications the same way whether it is open or only the tray
/// surface is alive. When the app is not running, nothing here ticks.
class UpdateWatchService {
  UpdateWatchService({
    required this.watcher,
    required this.settings,
    required this.notify,
    required this.texts,
    this.onRefreshed,
    this.interval = const Duration(hours: 1),
    this.onError = _reportError,
  });

  final CatalogUpdateWatcher watcher;

  /// Read on every tick, so toggling a setting takes effect from the next
  /// tick without rescheduling.
  final AppSettings Function() settings;
  final ShowNotification notify;
  final WatchTexts texts;

  /// Called after every successful fetch, before anything is announced, so
  /// the window's own catalog follows what the background just learned and
  /// is up to date when it is reopened from the tray.
  final Future<void> Function()? onRefreshed;

  final Duration interval;

  /// Called with fetch or notification failures. The default reports
  /// through [FlutterError.reportError], the convention for background
  /// probes: an unreachable catalog is never swallowed, and never blocks.
  final void Function(Object error, StackTrace stackTrace) onError;

  static void _reportError(Object error, StackTrace stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stackTrace),
    );
  }

  Timer? _timer;

  void start() {
    _timer ??= Timer.periodic(interval, (_) => check());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// One scheduled check; the timer and the tests call this directly.
  Future<void> check() async {
    final settings = this.settings();
    if (!settings.autoCheckUpdates) return;

    final CatalogUpdates? updates;
    try {
      updates = await watcher.poll();
    } catch (error, stack) {
      onError(error, stack);
      return;
    }
    try {
      await onRefreshed?.call();
    } catch (error, stack) {
      onError(error, stack);
    }
    if (updates == null || !settings.showNotifications) return;

    for (final package in updates.newPackages) {
      await _announce(
        title: texts.newSoftwareTitle,
        body: texts.newSoftwareBody(package.name),
        iconUrl: package.iconUrl,
      );
    }
    for (final package in updates.versionUpdates) {
      await _announce(
        title: texts.updateNotificationTitle,
        body: texts.updateNotificationBody(package.name, package.latestVersion),
        iconUrl: package.iconUrl,
      );
    }
  }

  Future<void> _announce({
    required String title,
    required String body,
    String? iconUrl,
  }) async {
    try {
      await notify(title: title, body: body, iconUrl: iconUrl);
    } catch (error, stack) {
      onError(error, stack);
    }
  }
}
