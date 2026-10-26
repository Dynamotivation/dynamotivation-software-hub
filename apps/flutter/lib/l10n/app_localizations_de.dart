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
  String get customPackageSubtitle => 'Benutzerdefiniert registriertes Paket';

  @override
  String get customPackageDescription =>
      'Benutzerdefiniert registriertes Paket aus Ihrem lokalen Katalog.';

  @override
  String get initialRegistration => 'Erstregistrierung des Pakets';

  @override
  String get packageRegistered => 'Paket registriert';

  @override
  String packageAddedToLibrary(String name) {
    return '„$name“ wurde Ihrer Softwarebibliothek hinzugefügt.';
  }

  @override
  String get latestSuffix => 'Neueste';

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
      'Benachrichtigen, wenn Updates oder Downloads abgeschlossen sind';

  @override
  String get softwareRegistration => 'Software-Registrierung';

  @override
  String get softwareRegistrationDescription =>
      'Eigene Softwarepakete registrieren oder die Katalogsynchronisierung manuell auslösen.';

  @override
  String get softwareNamePlaceholder => 'Name der Software...';

  @override
  String get register => 'Registrieren';

  @override
  String get refreshCatalog => 'Katalog aktualisieren';
}
