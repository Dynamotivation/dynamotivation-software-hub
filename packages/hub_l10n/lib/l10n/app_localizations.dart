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

  /// No description provided for @minimize.
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

  /// No description provided for @customPackageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Custom registered package'**
  String get customPackageSubtitle;

  /// No description provided for @customPackageDescription.
  ///
  /// In en, this message translates to:
  /// **'Custom registered package from your local catalog.'**
  String get customPackageDescription;

  /// No description provided for @initialRegistration.
  ///
  /// In en, this message translates to:
  /// **'Initial package registration'**
  String get initialRegistration;

  /// No description provided for @packageRegistered.
  ///
  /// In en, this message translates to:
  /// **'Package Registered'**
  String get packageRegistered;

  /// No description provided for @packageAddedToLibrary.
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" has been added to your software library.'**
  String packageAddedToLibrary(String name);

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
  /// **'Notify me when updates or downloads complete'**
  String get notificationsDescription;

  /// No description provided for @softwareRegistration.
  ///
  /// In en, this message translates to:
  /// **'Software Registration'**
  String get softwareRegistration;

  /// No description provided for @softwareRegistrationDescription.
  ///
  /// In en, this message translates to:
  /// **'Register custom software packages or manually trigger a catalog sync.'**
  String get softwareRegistrationDescription;

  /// No description provided for @softwareNamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Software name...'**
  String get softwareNamePlaceholder;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @refreshCatalog.
  ///
  /// In en, this message translates to:
  /// **'Refresh catalog'**
  String get refreshCatalog;

  /// No description provided for @packageAlreadyRegistered.
  ///
  /// In en, this message translates to:
  /// **'A package named \"{name}\" is already registered.'**
  String packageAlreadyRegistered(String name);

  /// No description provided for @invalidPackageName.
  ///
  /// In en, this message translates to:
  /// **'Enter a software name containing letters or digits.'**
  String get invalidPackageName;

  /// No description provided for @operationFailed.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get operationFailed;
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
