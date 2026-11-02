import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
  ];

  /// Window / app title
  ///
  /// In en, this message translates to:
  /// **'Dynamotivation Software Hub'**
  String get appTitle;

  /// Brand name shown above the product name in the header
  ///
  /// In en, this message translates to:
  /// **'Dynamotivation'**
  String get brandName;

  /// Product name shown in the header
  ///
  /// In en, this message translates to:
  /// **'Software Hub'**
  String get productName;

  /// Window menu item: minimize the window to the Dock
  ///
  /// In en, this message translates to:
  /// **'Minimize'**
  String get minimize;

  /// No description provided for @restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get restore;

  /// No description provided for @maximize.
  ///
  /// In en, this message translates to:
  /// **'Maximize'**
  String get maximize;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @backToSoftware.
  ///
  /// In en, this message translates to:
  /// **'Back to Software'**
  String get backToSoftware;

  /// Tooltip for the header update pill
  ///
  /// In en, this message translates to:
  /// **'Software Hub update available ({version})'**
  String hubUpdateAvailableTooltip(String version);

  /// No description provided for @hubUpToDate.
  ///
  /// In en, this message translates to:
  /// **'Hub is up to date'**
  String get hubUpToDate;

  /// No description provided for @hubUpdateTitle.
  ///
  /// In en, this message translates to:
  /// **'Software Hub Update'**
  String get hubUpdateTitle;

  /// No description provided for @hubUpdateReady.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready to install.'**
  String hubUpdateReady(String version);

  /// No description provided for @hubRunningLatest.
  ///
  /// In en, this message translates to:
  /// **'You are running the latest version.'**
  String get hubRunningLatest;

  /// No description provided for @updateNow.
  ///
  /// In en, this message translates to:
  /// **'Update now'**
  String get updateNow;

  /// Header pill label
  ///
  /// In en, this message translates to:
  /// **'Update Hub'**
  String get updateHub;

  /// No description provided for @catalogSynchronized.
  ///
  /// In en, this message translates to:
  /// **'Catalog Synchronized'**
  String get catalogSynchronized;

  /// No description provided for @catalogUpToDate.
  ///
  /// In en, this message translates to:
  /// **'All software package listings are up to date.'**
  String get catalogUpToDate;

  /// No description provided for @packageUpdatedTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Updated'**
  String packageUpdatedTitle(String name);

  /// No description provided for @packageUpdatedContent.
  ///
  /// In en, this message translates to:
  /// **'Successfully updated to v{version}.'**
  String packageUpdatedContent(String version);

  /// No description provided for @launchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Launching {name}'**
  String launchingTitle(String name);

  /// No description provided for @launchingContent.
  ///
  /// In en, this message translates to:
  /// **'Starting v{version}...'**
  String launchingContent(String version);

  /// No description provided for @selectPackagePrompt.
  ///
  /// In en, this message translates to:
  /// **'Select a software package to view details'**
  String get selectPackagePrompt;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailable;

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'Installed'**
  String get installed;

  /// No description provided for @available.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// No description provided for @updateToVersion.
  ///
  /// In en, this message translates to:
  /// **'Update to v{version}'**
  String updateToVersion(String version);

  /// No description provided for @launch.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get launch;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel Download'**
  String get cancelDownload;

  /// No description provided for @installVersion.
  ///
  /// In en, this message translates to:
  /// **'Install v{version}'**
  String installVersion(String version);

  /// No description provided for @openInstallFolder.
  ///
  /// In en, this message translates to:
  /// **'Open install folder'**
  String get openInstallFolder;

  /// No description provided for @verifyFiles.
  ///
  /// In en, this message translates to:
  /// **'Verify files'**
  String get verifyFiles;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @aboutThisSoftware.
  ///
  /// In en, this message translates to:
  /// **'About this software'**
  String get aboutThisSoftware;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @olderReleases.
  ///
  /// In en, this message translates to:
  /// **'Older releases ({count})'**
  String olderReleases(int count);

  /// No description provided for @searchSoftware.
  ///
  /// In en, this message translates to:
  /// **'Search software...'**
  String get searchSoftware;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeSystemDescription.
  ///
  /// In en, this message translates to:
  /// **'Matches OS mode'**
  String get themeSystemDescription;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeLightDescription.
  ///
  /// In en, this message translates to:
  /// **'Vibrant coral'**
  String get themeLightDescription;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @themeDarkDescription.
  ///
  /// In en, this message translates to:
  /// **'Deep maroon & charcoal'**
  String get themeDarkDescription;

  /// No description provided for @systemIntegration.
  ///
  /// In en, this message translates to:
  /// **'System Integration'**
  String get systemIntegration;

  /// No description provided for @autostartTitle.
  ///
  /// In en, this message translates to:
  /// **'Autostart in background'**
  String get autostartTitle;

  /// No description provided for @autostartDescription.
  ///
  /// In en, this message translates to:
  /// **'Start the Software Hub silently when you log in'**
  String get autostartDescription;

  /// No description provided for @keepRunningTitle.
  ///
  /// In en, this message translates to:
  /// **'Keep running in background'**
  String get keepRunningTitle;

  /// No description provided for @keepRunningDescription.
  ///
  /// In en, this message translates to:
  /// **'Stay in the system tray when the window is closed'**
  String get keepRunningDescription;

  /// No description provided for @autoCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically check for updates'**
  String get autoCheckTitle;

  /// No description provided for @autoCheckDescription.
  ///
  /// In en, this message translates to:
  /// **'Periodically check whether installed software or the Hub has a newer version'**
  String get autoCheckDescription;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Show notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsDescription.
  ///
  /// In en, this message translates to:
  /// **'Notify me when new software appears or a newer version is available'**
  String get notificationsDescription;

  /// System tray menu item: show the hub window
  ///
  /// In en, this message translates to:
  /// **'Open Software Hub'**
  String get trayOpenSoftwareHub;

  /// System tray menu item: close the hub process
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get trayEnd;

  /// Title of the background notification for a new catalog entry
  ///
  /// In en, this message translates to:
  /// **'New software available'**
  String get newSoftwareTitle;

  /// Body of the background notification for a new catalog entry
  ///
  /// In en, this message translates to:
  /// **'{name} has been added to the Software Hub.'**
  String newSoftwareBody(String name);

  /// Body of the background notification for a newer release; the title is updateAvailable
  ///
  /// In en, this message translates to:
  /// **'{name} v{version} is available.'**
  String updateNotificationBody(String name, String version);

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get operationFailed;

  /// Title of the View menu in the macOS menu bar
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get menuView;

  /// Title of the app-specific software menu in the macOS menu bar
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get menuSoftware;

  /// Title of the standard Window menu in the macOS menu bar
  ///
  /// In en, this message translates to:
  /// **'Window'**
  String get menuWindow;

  /// App menu item that opens the About dialog
  ///
  /// In en, this message translates to:
  /// **'About {productName}'**
  String aboutMenuItem(String productName);

  /// Window menu item: toggle between the window's saved size and a content-fitting size
  ///
  /// In en, this message translates to:
  /// **'Zoom'**
  String get zoom;

  /// View menu item while the window is not full screen
  ///
  /// In en, this message translates to:
  /// **'Enter Full Screen'**
  String get enterFullScreen;

  /// View menu item while the window is full screen
  ///
  /// In en, this message translates to:
  /// **'Exit Full Screen'**
  String get exitFullScreen;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @uninstallConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall {name}?'**
  String uninstallConfirmTitle(String name);

  /// No description provided for @uninstallConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It will be removed from this device. You can install it again at any time.'**
  String get uninstallConfirmBody;

  /// No description provided for @packageUninstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Uninstalled'**
  String packageUninstalledTitle(String name);

  /// No description provided for @packageUninstalledContent.
  ///
  /// In en, this message translates to:
  /// **'Removed from this device.'**
  String get packageUninstalledContent;

  /// No description provided for @packageInstalledTitle.
  ///
  /// In en, this message translates to:
  /// **'{name} Installed'**
  String packageInstalledTitle(String name);

  /// No description provided for @packageInstalledContent.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is ready to launch.'**
  String packageInstalledContent(String version);

  /// No description provided for @moreOptions.
  ///
  /// In en, this message translates to:
  /// **'More options'**
  String get moreOptions;

  /// Subtitle of the appearance preference in the Settings view
  ///
  /// In en, this message translates to:
  /// **'Choose between system, light or dark Yaru appearance'**
  String get appearanceSubtitle;

  /// Heading of the about section in the Settings view
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAboutHeading;

  /// Row title of the publisher entry in the Settings view
  ///
  /// In en, this message translates to:
  /// **'Publisher'**
  String get publisher;

  /// App version subtitle in the Settings about section
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsVersionLine(String version);

  /// Title of the metadata card in the package detail view
  ///
  /// In en, this message translates to:
  /// **'Package Details'**
  String get packageDetails;

  /// Heading of a release entry in the What's new and Older releases cards
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// Label of the identifier row in the package metadata card
  ///
  /// In en, this message translates to:
  /// **'Package ID'**
  String get packageId;

  /// Label of the installed version row in the package metadata card
  ///
  /// In en, this message translates to:
  /// **'Installed Version'**
  String get installedVersion;

  /// Label of the available version row in the package metadata card
  ///
  /// In en, this message translates to:
  /// **'Available Version'**
  String get availableVersion;

  /// Label of the status row in the package metadata card
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Value of the installed version row when the package is not installed
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @errorPackageNotFound.
  ///
  /// In en, this message translates to:
  /// **'The package \"{id}\" could not be found.'**
  String errorPackageNotFound(String id);

  /// Shown when the online software catalog cannot be fetched or parsed.
  ///
  /// In en, this message translates to:
  /// **'The software catalog could not be loaded. Check your connection and try again.'**
  String get errorCatalogUnavailable;

  /// No description provided for @errorActionRejected.
  ///
  /// In en, this message translates to:
  /// **'This action is not available for the package right now.'**
  String get errorActionRejected;

  /// Screen-reader indication for the selected software row
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get selectedPackage;

  /// Spoken enabled state following a switch label after activation
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get switchStateOn;

  /// Spoken disabled state following a switch label after activation
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get switchStateOff;

  /// Accessible label and tooltip for clearing the software search field
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['de', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
