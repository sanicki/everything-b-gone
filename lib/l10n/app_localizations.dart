import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('en')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Everything-B-Gone'**
  String get appTitle;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get unknownError;

  /// No description provided for @failedToStart.
  ///
  /// In en, this message translates to:
  /// **'Failed to start'**
  String get failedToStart;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @homeUsbDongleNotDetected.
  ///
  /// In en, this message translates to:
  /// **'No supported USB IR dongle detected. Plug it in and try again.'**
  String get homeUsbDongleNotDetected;

  /// No description provided for @requestUsbPermission.
  ///
  /// In en, this message translates to:
  /// **'Request USB permission'**
  String get requestUsbPermission;

  /// No description provided for @settingsNavLabel.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsNavLabel;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @noBrowserAvailable.
  ///
  /// In en, this message translates to:
  /// **'No browser available'**
  String get noBrowserAvailable;

  /// No description provided for @failedToOpen.
  ///
  /// In en, this message translates to:
  /// **'Failed to open: {error}'**
  String failedToOpen(Object error);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @themeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto Theme'**
  String get themeAuto;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light Theme'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark Theme'**
  String get themeDark;

  /// No description provided for @themeDescAuto.
  ///
  /// In en, this message translates to:
  /// **'Follows your device settings'**
  String get themeDescAuto;

  /// No description provided for @themeDescLight.
  ///
  /// In en, this message translates to:
  /// **'Always bright and clear'**
  String get themeDescLight;

  /// No description provided for @themeDescDark.
  ///
  /// In en, this message translates to:
  /// **'Easy on the eyes'**
  String get themeDescDark;

  /// No description provided for @themeHintAuto.
  ///
  /// In en, this message translates to:
  /// **'Theme automatically switches when you change your device settings between light and dark mode'**
  String get themeHintAuto;

  /// No description provided for @themeHintLight.
  ///
  /// In en, this message translates to:
  /// **'Perfect for daytime use and well-lit environments'**
  String get themeHintLight;

  /// No description provided for @themeHintDark.
  ///
  /// In en, this message translates to:
  /// **'Reduces eye strain in low-light conditions and saves battery on OLED screens'**
  String get themeHintDark;

  /// No description provided for @appearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearanceTitle;

  /// No description provided for @appearanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your visual experience'**
  String get appearanceSubtitle;

  /// No description provided for @useDynamicColors.
  ///
  /// In en, this message translates to:
  /// **'Use dynamic colors'**
  String get useDynamicColors;

  /// No description provided for @themeChoiceAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeChoiceAuto;

  /// No description provided for @themeChoiceLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeChoiceLight;

  /// No description provided for @themeChoiceDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeChoiceDark;

  /// No description provided for @irTransmitterTitle.
  ///
  /// In en, this message translates to:
  /// **'IR Transmitter'**
  String get irTransmitterTitle;

  /// No description provided for @irTransmitterSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which hardware sends IR commands'**
  String get irTransmitterSubtitle;

  /// No description provided for @interactionTitle.
  ///
  /// In en, this message translates to:
  /// **'Interaction'**
  String get interactionTitle;

  /// No description provided for @interactionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Touch feedback and remote layout'**
  String get interactionSubtitle;

  /// No description provided for @hapticFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Haptic feedback'**
  String get hapticFeedbackTitle;

  /// No description provided for @hapticFeedbackSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Vibrate on taps and actions'**
  String get hapticFeedbackSubtitle;

  /// No description provided for @forceInAppVibrationTitle.
  ///
  /// In en, this message translates to:
  /// **'Force in-app vibration'**
  String get forceInAppVibrationTitle;

  /// No description provided for @forceInAppVibrationBlockedMasterWarning.
  ///
  /// In en, this message translates to:
  /// **'Android system vibration is disabled. Force in-app vibration cannot override it on this device.'**
  String get forceInAppVibrationBlockedMasterWarning;

  /// No description provided for @forceInAppVibrationNoVibratorWarning.
  ///
  /// In en, this message translates to:
  /// **'This device reports no vibrator hardware, so in-app vibration cannot work.'**
  String get forceInAppVibrationNoVibratorWarning;

  /// No description provided for @intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get intensity;

  /// No description provided for @intensityLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get intensityLight;

  /// No description provided for @intensityMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get intensityMedium;

  /// No description provided for @intensityStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get intensityStrong;

  /// Settings slider title for the extra pause added between signals during a Power/Mute run.
  ///
  /// In en, this message translates to:
  /// **'Reaction time'**
  String get reactionTimeTitle;

  /// Settings slider subtitle explaining the reaction time delay.
  ///
  /// In en, this message translates to:
  /// **'Extra pause added before each signal during a Power or Mute run, so you have time to see a result before the next one fires.'**
  String get reactionTimeSubtitle;

  /// Current value readout next to the reaction time slider.
  ///
  /// In en, this message translates to:
  /// **'+{seconds}s'**
  String reactionTimeValueLabel(Object seconds);

  /// Settings toggle title for showing or hiding technical metadata on remote buttons.
  ///
  /// In en, this message translates to:
  /// **'Show button technical labels'**
  String get remoteButtonMetadataTitle;

  /// Settings toggle subtitle for showing or hiding protocol, code, and frequency labels on remote buttons.
  ///
  /// In en, this message translates to:
  /// **'Display protocol, code, and frequency chips on remote buttons.'**
  String get remoteButtonMetadataSubtitle;

  /// Snackbar shown when remote button technical metadata is enabled.
  ///
  /// In en, this message translates to:
  /// **'Button technical labels shown.'**
  String get remoteButtonMetadataShown;

  /// Snackbar shown when remote button technical metadata is disabled.
  ///
  /// In en, this message translates to:
  /// **'Button technical labels hidden.'**
  String get remoteButtonMetadataHidden;

  /// No description provided for @flipRemoteDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'Flip Remote View by default'**
  String get flipRemoteDefaultTitle;

  /// No description provided for @flipRemoteDefaultSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open Remote screens rotated 180° (for bottom-mounted USB dongles).'**
  String get flipRemoteDefaultSubtitle;

  /// No description provided for @remoteViewFlipped.
  ///
  /// In en, this message translates to:
  /// **'Remote View will open flipped.'**
  String get remoteViewFlipped;

  /// No description provided for @remoteViewNormal.
  ///
  /// In en, this message translates to:
  /// **'Remote View will open normally.'**
  String get remoteViewNormal;

  /// No description provided for @aboutTitle.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get aboutTitle;

  /// No description provided for @aboutSubtitle.
  ///
  /// In en, this message translates to:
  /// **'App information and open-source details'**
  String get aboutSubtitle;

  /// No description provided for @aboutAppNameWithCreator.
  ///
  /// In en, this message translates to:
  /// **'Everything-B-Gone'**
  String get aboutAppNameWithCreator;

  /// No description provided for @versionLabel.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(Object version);

  /// No description provided for @sourceCode.
  ///
  /// In en, this message translates to:
  /// **'Source Code'**
  String get sourceCode;

  /// No description provided for @viewOnGitHub.
  ///
  /// In en, this message translates to:
  /// **'View on GitHub'**
  String get viewOnGitHub;

  /// No description provided for @repositoryUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Repository URL copied'**
  String get repositoryUrlCopied;

  /// No description provided for @reportIssue.
  ///
  /// In en, this message translates to:
  /// **'Report Issue'**
  String get reportIssue;

  /// No description provided for @reportIssueSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bug reports & feature requests'**
  String get reportIssueSubtitle;

  /// No description provided for @issuesUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'Issues URL copied'**
  String get issuesUrlCopied;

  /// No description provided for @license.
  ///
  /// In en, this message translates to:
  /// **'License'**
  String get license;

  /// No description provided for @openSourceLicense.
  ///
  /// In en, this message translates to:
  /// **'Open-source license'**
  String get openSourceLicense;

  /// No description provided for @licenseUrlCopied.
  ///
  /// In en, this message translates to:
  /// **'License URL copied'**
  String get licenseUrlCopied;

  /// No description provided for @licenses.
  ///
  /// In en, this message translates to:
  /// **'Licenses'**
  String get licenses;

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get openSourceLicenses;

  /// No description provided for @deviceControlsTitle.
  ///
  /// In en, this message translates to:
  /// **'Device Controls'**
  String get deviceControlsTitle;

  /// No description provided for @deviceControlsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Show favorite buttons in the system controls page'**
  String get deviceControlsSubtitle;

  /// No description provided for @manageFavorites.
  ///
  /// In en, this message translates to:
  /// **'Manage favorites'**
  String get manageFavorites;

  /// No description provided for @manageFavoritesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which buttons appear in device controls'**
  String get manageFavoritesSubtitle;

  /// No description provided for @quickSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings'**
  String get quickSettingsTitle;

  /// No description provided for @quickSettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add tiles for power and volume shortcuts'**
  String get quickSettingsSubtitle;

  /// No description provided for @configureTiles.
  ///
  /// In en, this message translates to:
  /// **'Configure tiles'**
  String get configureTiles;

  /// No description provided for @configureTilesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Map tiles to remote buttons'**
  String get configureTilesSubtitle;

  /// No description provided for @failedToLoadTransmitterSettings.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transmitter settings.'**
  String get failedToLoadTransmitterSettings;

  /// No description provided for @usbStatusReady.
  ///
  /// In en, this message translates to:
  /// **'USB dongle is connected and ready to send IR.'**
  String get usbStatusReady;

  /// No description provided for @usbStatusPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'USB dongle detected. Request USB permission and approve the system prompt.'**
  String get usbStatusPermissionRequired;

  /// No description provided for @usbStatusPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'USB permission was denied for the attached dongle. Request it again and approve the prompt.'**
  String get usbStatusPermissionDenied;

  /// No description provided for @usbStatusPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'USB permission is granted. The dongle still needs to be initialized before it can send IR.'**
  String get usbStatusPermissionGranted;

  /// No description provided for @usbStatusOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'USB permission is granted, but the dongle could not be initialized. Reconnect it and try again.'**
  String get usbStatusOpenFailed;

  /// No description provided for @usbStatusNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No supported USB IR dongle detected.'**
  String get usbStatusNoDevice;

  /// No description provided for @usbSelectPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'USB dongle detected but not authorized. Tap \"Request USB permission\".'**
  String get usbSelectPermissionRequired;

  /// No description provided for @usbSelectPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'USB permission was denied. Tap \"Request USB permission\" and approve the prompt.'**
  String get usbSelectPermissionDenied;

  /// No description provided for @usbSelectPermissionGranted.
  ///
  /// In en, this message translates to:
  /// **'USB permission is granted, but the dongle is not initialized yet. Try reconnecting it.'**
  String get usbSelectPermissionGranted;

  /// No description provided for @usbSelectOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'USB permission is granted, but the dongle could not be initialized. Reconnect it and try again.'**
  String get usbSelectOpenFailed;

  /// No description provided for @usbSelectNoDevice.
  ///
  /// In en, this message translates to:
  /// **'No supported USB IR dongle detected. Plug it in, then tap \"Request USB permission\".'**
  String get usbSelectNoDevice;

  /// No description provided for @usbSelectReady.
  ///
  /// In en, this message translates to:
  /// **'USB dongle is ready.'**
  String get usbSelectReady;

  /// No description provided for @autoSwitchEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Auto-switch enabled: uses USB when connected, otherwise Internal.'**
  String get autoSwitchEnabledMessage;

  /// No description provided for @autoSwitchDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Auto-switch disabled: transmitter selection is now manual.'**
  String get autoSwitchDisabledMessage;

  /// No description provided for @failedToUpdateAutoSwitch.
  ///
  /// In en, this message translates to:
  /// **'Failed to update auto-switch setting.'**
  String get failedToUpdateAutoSwitch;

  /// No description provided for @failedToSwitchTransmitter.
  ///
  /// In en, this message translates to:
  /// **'Failed to switch transmitter.'**
  String get failedToSwitchTransmitter;

  /// No description provided for @deviceHasNoInternalIr.
  ///
  /// In en, this message translates to:
  /// **'This device has no built-in IR emitter.'**
  String get deviceHasNoInternalIr;

  /// No description provided for @audioModeEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Audio mode enabled. Use max media volume and an audio-to-IR LED adapter.'**
  String get audioModeEnabledMessage;

  /// No description provided for @usbPermissionRequestSent.
  ///
  /// In en, this message translates to:
  /// **'USB permission request sent.'**
  String get usbPermissionRequestSent;

  /// No description provided for @usbPermissionRequestSentApprove.
  ///
  /// In en, this message translates to:
  /// **'USB permission request sent. Approve the prompt to enable USB.'**
  String get usbPermissionRequestSentApprove;

  /// No description provided for @usbAlreadyReady.
  ///
  /// In en, this message translates to:
  /// **'USB dongle is already initialized and ready.'**
  String get usbAlreadyReady;

  /// No description provided for @failedToRequestUsbPermission.
  ///
  /// In en, this message translates to:
  /// **'Failed to request USB permission.'**
  String get failedToRequestUsbPermission;

  /// No description provided for @transmitterHelpInternal.
  ///
  /// In en, this message translates to:
  /// **'Use the phone’s built-in IR emitter to send commands.'**
  String get transmitterHelpInternal;

  /// No description provided for @transmitterHelpUsb.
  ///
  /// In en, this message translates to:
  /// **'Use a USB IR dongle (permission required) to send commands.'**
  String get transmitterHelpUsb;

  /// No description provided for @transmitterHelpAudio1.
  ///
  /// In en, this message translates to:
  /// **'Use audio output (mono). Requires an audio-to-IR LED adapter and high media volume.'**
  String get transmitterHelpAudio1;

  /// No description provided for @transmitterHelpAudio2.
  ///
  /// In en, this message translates to:
  /// **'Use audio output (stereo). Uses two channels for improved LED driving with compatible adapters.'**
  String get transmitterHelpAudio2;

  /// No description provided for @transmitterInternal.
  ///
  /// In en, this message translates to:
  /// **'Internal IR'**
  String get transmitterInternal;

  /// No description provided for @transmitterUsb.
  ///
  /// In en, this message translates to:
  /// **'USB IR Dongle'**
  String get transmitterUsb;

  /// No description provided for @transmitterAudio1.
  ///
  /// In en, this message translates to:
  /// **'Audio (1 LED)'**
  String get transmitterAudio1;

  /// No description provided for @transmitterAudio2.
  ///
  /// In en, this message translates to:
  /// **'Audio (2 LEDs)'**
  String get transmitterAudio2;

  /// No description provided for @failedToLoadTransmitterCapabilities.
  ///
  /// In en, this message translates to:
  /// **'Failed to load transmitter capabilities.'**
  String get failedToLoadTransmitterCapabilities;

  /// No description provided for @selectedTransmitter.
  ///
  /// In en, this message translates to:
  /// **'Selected transmitter'**
  String get selectedTransmitter;

  /// No description provided for @selectedTransmitterValue.
  ///
  /// In en, this message translates to:
  /// **'{effective} • Active: {active}'**
  String selectedTransmitterValue(Object effective, Object active);

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @autoSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-switch'**
  String get autoSwitchTitle;

  /// No description provided for @autoSwitchDisabledWhileAudio.
  ///
  /// In en, this message translates to:
  /// **'Disabled while using Audio mode'**
  String get autoSwitchDisabledWhileAudio;

  /// No description provided for @autoSwitchUsesUsbOtherwiseInternal.
  ///
  /// In en, this message translates to:
  /// **'Uses USB when connected, otherwise Internal'**
  String get autoSwitchUsesUsbOtherwiseInternal;

  /// No description provided for @unavailableOnThisDevice.
  ///
  /// In en, this message translates to:
  /// **'Unavailable on this device'**
  String get unavailableOnThisDevice;

  /// No description provided for @openOnUsbAttachTitle.
  ///
  /// In en, this message translates to:
  /// **'Open on USB attach'**
  String get openOnUsbAttachTitle;

  /// No description provided for @openOnUsbAttachSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Android may suggest opening the app when a supported USB IR dongle is connected.'**
  String get openOnUsbAttachSubtitle;

  /// No description provided for @openOnUsbAttachEnabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Will suggest opening Everything-B-Gone when a supported USB dongle is attached.'**
  String get openOnUsbAttachEnabledMessage;

  /// No description provided for @openOnUsbAttachDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Won\'t suggest opening on USB attach.'**
  String get openOnUsbAttachDisabledMessage;

  /// No description provided for @failedToUpdateSetting.
  ///
  /// In en, this message translates to:
  /// **'Failed to update setting.'**
  String get failedToUpdateSetting;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brand;

  /// No description provided for @unknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// No description provided for @deviceCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Device Code'**
  String get deviceCodeLabel;

  /// No description provided for @commandLabel.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get commandLabel;

  /// No description provided for @editButtonCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Code of the button'**
  String get editButtonCodeTitle;

  /// No description provided for @test.
  ///
  /// In en, this message translates to:
  /// **'Test'**
  String get test;

  /// No description provided for @saveAction.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveAction;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get running;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get start;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Settings toggle title for showing the compact device controls row on the home surface.
  ///
  /// In en, this message translates to:
  /// **'Show quick controls on home'**
  String get showDeviceControlsOnHome;

  /// Settings toggle subtitle for showing the compact device controls row on the home surface.
  ///
  /// In en, this message translates to:
  /// **'Show the compact Power, Mute, and Volume row on the main screen.'**
  String get showDeviceControlsOnHomeSubtitle;

  /// Snackbar shown when the home quick controls row is enabled.
  ///
  /// In en, this message translates to:
  /// **'Quick controls shown on home.'**
  String get homeDeviceControlsShown;

  /// Snackbar shown when the home quick controls row is disabled.
  ///
  /// In en, this message translates to:
  /// **'Quick controls hidden from home.'**
  String get homeDeviceControlsHidden;

  /// Short label for the power control.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get power;

  /// Short label for the mute control.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// Title for the IR waveform visualization panel.
  ///
  /// In en, this message translates to:
  /// **'IR waveform'**
  String get irWaveformTitle;

  /// Number of active IR pulses in a waveform.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} pulse} other{{count} pulses}}'**
  String irWaveformPulseCount(int count);

  /// Longest off gap in an IR waveform.
  ///
  /// In en, this message translates to:
  /// **'Gap {duration}'**
  String irWaveformGapLabel(String duration);

  /// Number of timing durations in an IR waveform.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} duration} other{{count} durations}}'**
  String irWaveformDurationCount(int count);

  /// Explanation for high and low states in the IR waveform graph.
  ///
  /// In en, this message translates to:
  /// **'High means the IR LED carrier is active; low means silence.'**
  String get irWaveformActiveHint;

  /// Legend label for active carrier sections in an IR waveform.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get irWaveformOnLabel;

  /// Legend label for inactive/silent sections in an IR waveform.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get irWaveformOffLabel;

  /// Title for the Quick Settings tile configuration screen.
  ///
  /// In en, this message translates to:
  /// **'Quick Settings tiles'**
  String get quickSettingsTilesTitle;

  /// Label for the power Quick Settings tile.
  ///
  /// In en, this message translates to:
  /// **'Power tile'**
  String get quickSettingsPowerTile;

  /// Label for the mute Quick Settings tile.
  ///
  /// In en, this message translates to:
  /// **'Mute tile'**
  String get quickSettingsMuteTile;
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
      <String>['en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
