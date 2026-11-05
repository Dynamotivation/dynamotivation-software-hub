// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dynamotivation Software Hub';

  @override
  String get brandName => 'Dynamotivation';

  @override
  String get productName => 'Software Hub';

  @override
  String get minimize => 'Minimize';

  @override
  String get restore => 'Restore';

  @override
  String get maximize => 'Maximize';

  @override
  String get close => 'Close';

  @override
  String get settings => 'Settings';

  @override
  String get backToSoftware => 'Back to Software';

  @override
  String hubUpdateAvailableTooltip(String version) {
    return 'Software Hub update available ($version)';
  }

  @override
  String get hubUpToDate => 'Hub is up to date';

  @override
  String get hubUpdateTitle => 'Software Hub Update';

  @override
  String hubUpdateReady(String version) {
    return 'Version $version is ready to install.';
  }

  @override
  String get hubRunningLatest => 'You are running the latest version.';

  @override
  String get updateNow => 'Update now';

  @override
  String get updateHub => 'Update Hub';

  @override
  String get catalogSynchronized => 'Catalog Synchronized';

  @override
  String get catalogUpToDate => 'All software package listings are up to date.';

  @override
  String packageUpdatedTitle(String name) {
    return '$name Updated';
  }

  @override
  String packageUpdatedContent(String version) {
    return 'Successfully updated to v$version.';
  }

  @override
  String launchingTitle(String name) {
    return 'Launching $name';
  }

  @override
  String launchingContent(String version) {
    return 'Starting v$version...';
  }

  @override
  String get selectPackagePrompt => 'Select a software package to view details';

  @override
  String get updateAvailable => 'Update available';

  @override
  String get installed => 'Installed';

  @override
  String get available => 'Available';

  @override
  String updateToVersion(String version) {
    return 'Update to v$version';
  }

  @override
  String get launch => 'Launch';

  @override
  String get cancelDownload => 'Cancel Download';

  @override
  String installVersion(String version) {
    return 'Install v$version';
  }

  @override
  String get openInstallFolder => 'Open install folder';

  @override
  String get verifyFiles => 'Verify files';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get aboutThisSoftware => 'About this software';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get olderReleasesLoadFailed =>
      'Older releases could not be loaded. Check your connection.';

  @override
  String get retry => 'Try again';

  @override
  String olderReleases(int count) {
    return 'Older releases ($count)';
  }

  @override
  String get searchSoftware => 'Search software...';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get appearance => 'Appearance';

  @override
  String get themeSystem => 'System';

  @override
  String get themeSystemDescription => 'Matches OS mode';

  @override
  String get themeLight => 'Light';

  @override
  String get themeLightDescription => 'Vibrant coral';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeDarkDescription => 'Deep maroon & charcoal';

  @override
  String get systemIntegration => 'System Integration';

  @override
  String get autostartTitle => 'Autostart in background';

  @override
  String get autostartDescription =>
      'Start the Software Hub silently when you log in';

  @override
  String get keepRunningTitle => 'Keep running in background';

  @override
  String get keepRunningDescription =>
      'Stay in the system tray when the window is closed';

  @override
  String get autoCheckTitle => 'Automatically check for updates';

  @override
  String get autoCheckDescription =>
      'Periodically check whether installed software or the Hub has a newer version';

  @override
  String get notificationsTitle => 'Show notifications';

  @override
  String get notificationsDescription =>
      'Notify me when new software appears or a newer version is available';

  @override
  String get trayOpenSoftwareHub => 'Open Software Hub';

  @override
  String get trayEnd => 'End';

  @override
  String get newSoftwareTitle => 'New software available';

  @override
  String newSoftwareBody(String name) {
    return '$name has been added to the Software Hub.';
  }

  @override
  String updateNotificationBody(String name, String version) {
    return '$name v$version is available.';
  }

  @override
  String get operationFailed => 'Something went wrong';

  @override
  String get menuView => 'View';

  @override
  String get menuSoftware => 'Software';

  @override
  String get menuWindow => 'Window';

  @override
  String aboutMenuItem(String productName) {
    return 'About $productName';
  }

  @override
  String get zoom => 'Zoom';

  @override
  String get enterFullScreen => 'Enter Full Screen';

  @override
  String get exitFullScreen => 'Exit Full Screen';

  @override
  String get cancel => 'Cancel';

  @override
  String uninstallConfirmTitle(String name) {
    return 'Uninstall $name?';
  }

  @override
  String get uninstallConfirmBody =>
      'It will be removed from this device. You can install it again at any time.';

  @override
  String packageUninstalledTitle(String name) {
    return '$name Uninstalled';
  }

  @override
  String get packageUninstalledContent => 'Removed from this device.';

  @override
  String packageInstalledTitle(String name) {
    return '$name Installed';
  }

  @override
  String packageInstalledContent(String version) {
    return 'Version $version is ready to launch.';
  }

  @override
  String get moreOptions => 'More options';

  @override
  String get appearanceSubtitle =>
      'Choose between system, light or dark Yaru appearance';

  @override
  String get settingsAboutHeading => 'About';

  @override
  String get publisher => 'Publisher';

  @override
  String settingsVersionLine(String version) {
    return 'Version $version';
  }

  @override
  String get packageDetails => 'Package Details';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get packageId => 'Package ID';

  @override
  String get installedVersion => 'Installed Version';

  @override
  String get availableVersion => 'Available Version';

  @override
  String get status => 'Status';

  @override
  String get none => 'None';

  @override
  String errorPackageNotFound(String id) {
    return 'The package \"$id\" could not be found.';
  }

  @override
  String get errorCatalogUnavailable =>
      'The software catalog could not be loaded. Check your connection and try again.';

  @override
  String get errorActionRejected =>
      'This action is not available for the package right now.';

  @override
  String get selectedPackage => 'Selected';

  @override
  String get switchStateOn => 'on';

  @override
  String get switchStateOff => 'off';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get errorInstalledSoftwareUnavailable =>
      'Installed software could not be read from Windows. Try refreshing the software list.';

  @override
  String get errorLaunchFailed =>
      'The application could not be started. Refresh the software list and check that it is still installed.';

  @override
  String get running => 'Running';

  @override
  String get launchAnotherInstance => 'Launch another instance';

  @override
  String get forceClose => 'Force close';

  @override
  String get clickAction => 'click';

  @override
  String get yesAction => 'Yes';

  @override
  String get noAction => 'No';

  @override
  String forceCloseTitle(String name) {
    return 'Force close $name?';
  }

  @override
  String forceCloseBody(String name) {
    return 'Are you sure? All running instances of $name will be force closed. Unsaved changes will be lost.';
  }

  @override
  String modifierClickHint(String shortcut, String action) {
    return '$shortcut to $action.';
  }

  @override
  String get errorProcessOperation =>
      'The application processes could not be read or stopped. Check that they are running under your Windows account and try again.';
}
