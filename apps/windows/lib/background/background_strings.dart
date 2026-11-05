import 'package:flutter/widgets.dart';
import 'package:hub_l10n/hub_l10n.dart';

import 'update_watch_service.dart';

/// The localized strings the background surface shows outside the widget
/// tree (tray context menu, notifications). Loaded once at startup from the
/// same scope the app's presentation locale resolves against.
///
/// [WatchTexts] is implemented by the class holding these strings so the
/// watch service never depends on the notification wording's home.
class BackgroundStrings implements WatchTexts {
  BackgroundStrings._(AppLocalizations l10n)
    : _l10n = l10n,
      appName = l10n.appTitle;

  final AppLocalizations _l10n;

  final String appName;

  /// Loads the app language. Falls back to English when the platform
  /// locale has no translation and no matching delegate branch.
  static Future<BackgroundStrings> load(Locale locale) async {
    final l10n = await AppLocalizations.delegate.load(locale);
    return BackgroundStrings._(l10n);
  }

  String get trayOpenSoftwareHub => _l10n.trayOpenSoftwareHub;
  String get trayEnd => _l10n.trayEnd;
  @override
  String get newSoftwareTitle => _l10n.newSoftwareTitle;
  @override
  String get updateNotificationTitle => _l10n.updateAvailable;
  @override
  String newSoftwareBody(String name) => _l10n.newSoftwareBody(name);
  @override
  String updateNotificationBody(String name, String version) =>
      _l10n.updateNotificationBody(name, version);
  @override
  String get changesSummaryTitle => _l10n.catalogChangesTitle;
  @override
  String changesSummaryBody(int count) => _l10n.catalogChangesBody(count);
}
