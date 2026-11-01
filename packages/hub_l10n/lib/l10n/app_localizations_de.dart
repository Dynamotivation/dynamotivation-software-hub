// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Dynamotivation Software Hub';

  @override
  String get brandName => 'Dynamotivation';

  @override
  String get productName => 'Software Hub';

  @override
  String get minimize => 'Minimieren';

  @override
  String get restore => 'Wiederherstellen';

  @override
  String get maximize => 'Maximieren';

  @override
  String get close => 'Schließen';

  @override
  String get settings => 'Einstellungen';

  @override
  String get backToSoftware => 'Zurück zur Software';

  @override
  String hubUpdateAvailableTooltip(String version) {
    return 'Software-Hub-Update verfügbar ($version)';
  }

  @override
  String get hubUpToDate => 'Hub ist auf dem neuesten Stand';

  @override
  String get hubUpdateTitle => 'Software-Hub-Update';

  @override
  String hubUpdateReady(String version) {
    return 'Version $version kann installiert werden.';
  }

  @override
  String get hubRunningLatest => 'Sie verwenden die neueste Version.';

  @override
  String get updateNow => 'Jetzt aktualisieren';

  @override
  String get updateHub => 'Hub aktualisieren';

  @override
  String get catalogSynchronized => 'Katalog synchronisiert';

  @override
  String get catalogUpToDate =>
      'Alle Softwarepakete sind auf dem neuesten Stand.';

  @override
  String packageUpdatedTitle(String name) {
    return '$name aktualisiert';
  }

  @override
  String packageUpdatedContent(String version) {
    return 'Erfolgreich auf v$version aktualisiert.';
  }

  @override
  String launchingTitle(String name) {
    return '$name wird gestartet';
  }

  @override
  String launchingContent(String version) {
    return 'v$version wird gestartet...';
  }

  @override
  String get selectPackagePrompt =>
      'Wählen Sie ein Softwarepaket aus, um Details anzuzeigen';

  @override
  String get updateAvailable => 'Update verfügbar';

  @override
  String get installed => 'Installiert';

  @override
  String get available => 'Verfügbar';

  @override
  String updateToVersion(String version) {
    return 'Auf v$version aktualisieren';
  }

  @override
  String get launch => 'Starten';

  @override
  String get cancelDownload => 'Download abbrechen';

  @override
  String installVersion(String version) {
    return 'v$version installieren';
  }

  @override
  String get openInstallFolder => 'Installationsordner öffnen';

  @override
  String get verifyFiles => 'Dateien überprüfen';

  @override
  String get uninstall => 'Deinstallieren';

  @override
  String get aboutThisSoftware => 'Über diese Software';

  @override
  String get whatsNew => 'Neuigkeiten';

  @override
  String olderReleases(int count) {
    return 'Ältere Versionen ($count)';
  }

  @override
  String get searchSoftware => 'Software suchen...';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get appearance => 'Darstellung';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDescription => 'Folgt dem Betriebssystem';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeLightDescription => 'Leuchtendes Koralle';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get themeDarkDescription => 'Tiefes Kastanienbraun & Anthrazit';

  @override
  String get systemIntegration => 'Systemintegration';

  @override
  String get autostartTitle => 'Automatisch im Hintergrund starten';

  @override
  String get autostartDescription =>
      'Software Hub bei der Anmeldung unauffällig starten';

  @override
  String get keepRunningTitle => 'Im Hintergrund weiterlaufen';

  @override
  String get keepRunningDescription =>
      'Beim Schließen des Fensters im Infobereich bleiben';

  @override
  String get autoCheckTitle => 'Automatisch nach Updates suchen';

  @override
  String get autoCheckDescription =>
      'Regelmäßig prüfen, ob für installierte Software oder den Hub eine neuere Version vorliegt';

  @override
  String get notificationsTitle => 'Benachrichtigungen anzeigen';

  @override
  String get notificationsDescription =>
      'Benachrichtigen, wenn neue Software erscheint oder eine neuere Version verfügbar ist';

  @override
  String get trayOpenSoftwareHub => 'Software Hub öffnen';

  @override
  String get trayEnd => 'Beenden';

  @override
  String get newSoftwareTitle => 'Neue Software verfügbar';

  @override
  String newSoftwareBody(String name) {
    return '$name wurde dem Software Hub hinzugefügt.';
  }

  @override
  String updateNotificationBody(String name, String version) {
    return '$name v$version ist verfügbar.';
  }

  @override
  String get operationFailed => 'Etwas ist schiefgelaufen';

  @override
  String get menuView => 'Ansicht';

  @override
  String get menuSoftware => 'Software';

  @override
  String get menuWindow => 'Fenster';

  @override
  String aboutMenuItem(String productName) {
    return 'Über $productName';
  }

  @override
  String get zoom => 'Zoom';

  @override
  String get enterFullScreen => 'Vollbild aktivieren';

  @override
  String get exitFullScreen => 'Vollbild beenden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String uninstallConfirmTitle(String name) {
    return '$name deinstallieren?';
  }

  @override
  String get uninstallConfirmBody =>
      'Die Software wird von diesem Gerät entfernt. Du kannst sie jederzeit erneut installieren.';

  @override
  String packageUninstalledTitle(String name) {
    return '$name deinstalliert';
  }

  @override
  String get packageUninstalledContent => 'Von diesem Gerät entfernt.';

  @override
  String packageInstalledTitle(String name) {
    return '$name installiert';
  }

  @override
  String packageInstalledContent(String version) {
    return 'Version $version kann gestartet werden.';
  }

  @override
  String get moreOptions => 'Weitere Optionen';

  @override
  String get appearanceSubtitle =>
      'Zwischen dem System-, hellen und dunklen Yaru-Erscheinungsbild wählen';

  @override
  String get settingsAboutHeading => 'Über';

  @override
  String get publisher => 'Herausgeber';

  @override
  String settingsVersionLine(String version) {
    return 'Version $version';
  }

  @override
  String get packageDetails => 'Paketdetails';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get packageId => 'Paket-ID';

  @override
  String get installedVersion => 'Installierte Version';

  @override
  String get availableVersion => 'Verfügbare Version';

  @override
  String get status => 'Status';

  @override
  String get none => 'Keine';

  @override
  String errorPackageNotFound(String id) {
    return 'Das Paket \"$id\" wurde nicht gefunden.';
  }

  @override
  String get errorCatalogUnavailable =>
      'Der Software-Katalog konnte nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get errorActionRejected =>
      'Diese Aktion ist für das Paket derzeit nicht verfügbar.';

  @override
  String get clearSearch => 'Suche löschen';
}
