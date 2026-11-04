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

/// Signature the composition root wires to the in-app notification surface
/// (a banner in the hub window). It must not take focus.
typedef ShowInAppNotice = void Function({
  required String title,
  required String message,
});

/// The localized words the watch service needs. [BackgroundStrings]
/// provides the implementation.
abstract class WatchTexts {
  String get newSoftwareTitle;
  String get updateNotificationTitle;
  String get changesSummaryTitle;
  String newSoftwareBody(String name);
  String updateNotificationBody(String name, String version);
  String changesSummaryBody(int count);
}

/// The announcing half of background running: about once an hour the catalog
/// is fetched again, and right after startup what the user was not told
/// about before the last close is announced once.
///
/// Notification policy:
///  - Where: a focused hub window gets an in-app notice ([showInApp]); the OS
///    toast ([notify]) is only for a window that is unfocused or hidden in the
///    tray. A click on a toast brings the window up (wired in `main.dart`).
///  - How much: one change is announced by name, several collapse into one
///    summary. Never one notification per app.
///  - How often: what was announced is persisted by the [watcher] (per
///    package and version), so a restart, including the restart after a
///    self-update, does not repeat it.
///  - Settings: *Automatically check for updates* off means nothing is
///    fetched or announced; *Show notifications* off means fetched, nothing
///    shown. What is not shown because of a setting counts as known, so
///    switching a setting on later does not dump old news.
/// When the app is not running, nothing here ticks.
class UpdateWatchService {
  UpdateWatchService({
    required this.watcher,
    required this.settings,
    required this.notify,
    required this.showInApp,
    required this.isWindowFocused,
    required this.texts,
    this.onRefreshed,
    this.interval = const Duration(hours: 1),
    this.onError = _reportError,
  });

  final CatalogUpdateWatcher watcher;

  /// Read on every tick, so toggling a setting takes effect from the next
  /// tick without rescheduling.
  final AppSettings Function() settings;

  /// The OS toast. Used only while the window is not focused.
  final ShowNotification notify;

  /// The in-app notice. Used while the window is focused.
  final ShowInAppNotice showInApp;

  /// True while the hub window is visible and has the keyboard focus.
  final Future<bool> Function() isWindowFocused;

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
    if (!settings().autoCheckUpdates) return;

    final CatalogUpdates updates;
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
    await _deliver(updates);
  }

  /// The check after startup, once the window showed the catalog: announces
  /// at most one summary of what was not announced before the app last
  /// closed. Nothing is fetched here; the startup load just did.
  Future<void> announceStartup() async {
    try {
      if (!settings().autoCheckUpdates) {
        await watcher.markSeen();
        return;
      }
      await _deliver(await watcher.pending());
    } catch (error, stack) {
      onError(error, stack);
    }
  }

  /// Tells the user about [updates] in the one fitting place, once.
  Future<void> _deliver(CatalogUpdates updates) async {
    if (updates.isEmpty) return;
    if (settings().showNotifications) {
      final (:title, :body, :iconUrl) = _compose(updates);
      try {
        if (await isWindowFocused()) {
          showInApp(title: title, message: body);
        } else {
          await notify(title: title, body: body, iconUrl: iconUrl);
        }
      } catch (error, stack) {
        // Not marked as announced: the next check tries again.
        onError(error, stack);
        return;
      }
    }
    try {
      await watcher.markAnnounced(updates);
    } catch (error, stack) {
      onError(error, stack);
    }
  }

  /// One change is named; several collapse into a summary with a count.
  ({String title, String body, String? iconUrl}) _compose(
    CatalogUpdates updates,
  ) {
    if (updates.count == 1) {
      final package = updates.packages.single;
      return updates.newPackages.isNotEmpty
          ? (
              title: texts.newSoftwareTitle,
              body: texts.newSoftwareBody(package.name),
              iconUrl: package.iconUrl,
            )
          : (
              title: texts.updateNotificationTitle,
              body: texts.updateNotificationBody(
                package.name,
                package.latestVersion,
              ),
              iconUrl: package.iconUrl,
            );
    }
    return (
      title: texts.changesSummaryTitle,
      body: texts.changesSummaryBody(updates.count),
      iconUrl: null,
    );
  }
}
