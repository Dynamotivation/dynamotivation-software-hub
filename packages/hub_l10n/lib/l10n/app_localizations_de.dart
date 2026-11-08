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
  String get updateHub => 'Hub aktualisieren';

  @override
  String hubUpdateDownloading(int percent) {
    return 'Wird geladen … $percent %';
  }

  @override
  String get errorSetupUnavailable =>
      'Das Update konnte nicht heruntergeladen werden. Prüfen Sie Ihre Verbindung und versuchen Sie es erneut.';

  @override
  String get errorSetupLaunchFailed =>
      'Das Update-Setup konnte nicht gestartet werden.';

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
  String get olderReleasesLoadFailed =>
      'Ältere Versionen konnten nicht geladen werden. Prüfe deine Verbindung.';

  @override
  String get retry => 'Erneut versuchen';

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
  String get newSoftwareTitle => 'Neue Software veröffentlicht';

  @override
  String newSoftwareBody(String name) {
    return '$name ist erschienen. Gehören Sie zu den Ersten, die es ausprobieren.';
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
  String get selectedPackage => 'Ausgewählt';

  @override
  String get switchStateOn => 'ein';

  @override
  String get switchStateOff => 'aus';

  @override
  String get clearSearch => 'Suche löschen';

  @override
  String get errorInstalledSoftwareUnavailable =>
      'Die installierte Software konnte nicht aus Windows gelesen werden. Aktualisiere die Softwareliste erneut.';

  @override
  String get errorLaunchFailed =>
      'Die Anwendung konnte nicht gestartet werden. Aktualisiere die Softwareliste und prüfe, ob sie noch installiert ist.';

  @override
  String get running => 'Läuft';

  @override
  String get launchAnotherInstance => 'Weitere Instanz starten';

  @override
  String get forceClose => 'Beenden erzwingen';

  @override
  String get clickAction => 'Klick';

  @override
  String get yesAction => 'Ja';

  @override
  String get noAction => 'Nein';

  @override
  String forceCloseTitle(String name) {
    return 'Beenden von $name erzwingen?';
  }

  @override
  String forceCloseBody(String name) {
    return 'Bist du sicher? Alle laufenden Instanzen von $name werden zwangsweise beendet. Ungespeicherte Änderungen gehen verloren.';
  }

  @override
  String modifierClickHint(String shortcut, String action) {
    return '$shortcut, um die Aktion „$action“ auszuführen.';
  }

  @override
  String get errorProcessOperation =>
      'Die Anwendungsprozesse konnten nicht gelesen oder beendet werden. Prüfe, ob sie unter deinem Windows-Konto laufen, und versuche es erneut.';

  @override
  String get hubUpdateRestart => 'Neu starten und aktualisieren';

  @override
  String hubUpdateReadyTooltip(String version) {
    return 'Version $version ist heruntergeladen. Neu starten, um zu aktualisieren; sonst wird sie beim Schließen des Hubs installiert.';
  }

  @override
  String get catalogChangesTitle => 'Neu im Software Hub';

  @override
  String catalogChangesBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Apps sind neu oder haben ein Update.',
      one: '1 App ist neu oder hat ein Update.',
    );
    return '$_temp0';
  }

  @override
  String get dismissNotification => 'Ausblenden';

  @override
  String setupDownloading(int percent) {
    return 'Wird heruntergeladen… $percent %';
  }

  @override
  String get setupInstalling => 'Wird installiert…';

  @override
  String get setupUpdating => 'Wird aktualisiert…';

  @override
  String errorSetupFailed(String path) {
    return 'Das Setup wurde nicht abgeschlossen. Details stehen im Protokoll: $path';
  }

  @override
  String get errorPackageInUse =>
      'Die Anwendung läuft. Schließe sie und versuche es erneut.';

  @override
  String get setupUninstalling => 'Wird deinstalliert…';

  @override
  String get installOtherVersion => 'Andere Version installieren…';

  @override
  String installVersionTitle(String name) {
    return 'Version von $name installieren';
  }

  @override
  String get installVersionBody =>
      'Die gewählte Version ersetzt die installierte. Ältere Versionen können mit neueren gespeicherte Dateien eventuell nicht öffnen.';

  @override
  String get installAction => 'Installieren';

  @override
  String get versionLatest => 'neueste';

  @override
  String get versionInstalled => 'installiert';

  @override
  String get versionNoDownload => 'kein Download für dieses Gerät';

  @override
  String get loadingVersions => 'Versionen werden geladen';

  @override
  String setupInstallingVersion(String version) {
    return 'v$version wird installiert…';
  }
}
