// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Everything-B-Gone';

  @override
  String get loading => 'Loading…';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get failedToStart => 'Failed to start';

  @override
  String get retry => 'Retry';

  @override
  String get homeUsbDongleNotDetected =>
      'No supported USB IR dongle detected. Plug it in and try again.';

  @override
  String get requestUsbPermission => 'Request USB permission';

  @override
  String get settingsNavLabel => 'Settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get noBrowserAvailable => 'No browser available';

  @override
  String failedToOpen(Object error) {
    return 'Failed to open: $error';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get themeAuto => 'Auto Theme';

  @override
  String get themeLight => 'Light Theme';

  @override
  String get themeDark => 'Dark Theme';

  @override
  String get themeDescAuto => 'Follows your device settings';

  @override
  String get themeDescLight => 'Always bright and clear';

  @override
  String get themeDescDark => 'Easy on the eyes';

  @override
  String get themeHintAuto =>
      'Theme automatically switches when you change your device settings between light and dark mode';

  @override
  String get themeHintLight =>
      'Perfect for daytime use and well-lit environments';

  @override
  String get themeHintDark =>
      'Reduces eye strain in low-light conditions and saves battery on OLED screens';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get appearanceSubtitle => 'Customize your visual experience';

  @override
  String get useDynamicColors => 'Use dynamic colors';

  @override
  String get themeChoiceAuto => 'Auto';

  @override
  String get themeChoiceLight => 'Light';

  @override
  String get themeChoiceDark => 'Dark';

  @override
  String get irTransmitterTitle => 'IR Transmitter';

  @override
  String get irTransmitterSubtitle => 'Choose which hardware sends IR commands';

  @override
  String get interactionTitle => 'Interaction';

  @override
  String get interactionSubtitle => 'Touch feedback and remote layout';

  @override
  String get hapticFeedbackTitle => 'Haptic feedback';

  @override
  String get hapticFeedbackSubtitle => 'Vibrate on taps and actions';

  @override
  String get forceInAppVibrationTitle => 'Force in-app vibration';

  @override
  String get forceInAppVibrationBlockedMasterWarning =>
      'Android system vibration is disabled. Force in-app vibration cannot override it on this device.';

  @override
  String get forceInAppVibrationNoVibratorWarning =>
      'This device reports no vibrator hardware, so in-app vibration cannot work.';

  @override
  String get intensity => 'Intensity';

  @override
  String get intensityLight => 'Light';

  @override
  String get intensityMedium => 'Medium';

  @override
  String get intensityStrong => 'Strong';

  @override
  String get remoteButtonMetadataTitle => 'Show button technical labels';

  @override
  String get remoteButtonMetadataSubtitle =>
      'Display protocol, code, and frequency chips on remote buttons.';

  @override
  String get remoteButtonMetadataShown => 'Button technical labels shown.';

  @override
  String get remoteButtonMetadataHidden => 'Button technical labels hidden.';

  @override
  String get flipRemoteDefaultTitle => 'Flip Remote View by default';

  @override
  String get flipRemoteDefaultSubtitle =>
      'Open Remote screens rotated 180° (for bottom-mounted USB dongles).';

  @override
  String get remoteViewFlipped => 'Remote View will open flipped.';

  @override
  String get remoteViewNormal => 'Remote View will open normally.';

  @override
  String get aboutTitle => 'About';

  @override
  String get aboutSubtitle => 'App information and open-source details';

  @override
  String get aboutAppNameWithCreator => 'Everything-B-Gone';

  @override
  String versionLabel(Object version) {
    return 'Version $version';
  }

  @override
  String get sourceCode => 'Source Code';

  @override
  String get viewOnGitHub => 'View on GitHub';

  @override
  String get repositoryUrlCopied => 'Repository URL copied';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get reportIssueSubtitle => 'Bug reports & feature requests';

  @override
  String get issuesUrlCopied => 'Issues URL copied';

  @override
  String get license => 'License';

  @override
  String get openSourceLicense => 'Open-source license';

  @override
  String get licenseUrlCopied => 'License URL copied';

  @override
  String get licenses => 'Licenses';

  @override
  String get openSourceLicenses => 'Open source licenses';

  @override
  String get deviceControlsTitle => 'Device Controls';

  @override
  String get deviceControlsSubtitle =>
      'Show favorite buttons in the system controls page';

  @override
  String get manageFavorites => 'Manage favorites';

  @override
  String get manageFavoritesSubtitle =>
      'Choose which buttons appear in device controls';

  @override
  String get quickSettingsTitle => 'Quick Settings';

  @override
  String get quickSettingsSubtitle =>
      'Add tiles for power and volume shortcuts';

  @override
  String get configureTiles => 'Configure tiles';

  @override
  String get configureTilesSubtitle => 'Map tiles to remote buttons';

  @override
  String get failedToLoadTransmitterSettings =>
      'Failed to load transmitter settings.';

  @override
  String get usbStatusReady => 'USB dongle is connected and ready to send IR.';

  @override
  String get usbStatusPermissionRequired =>
      'USB dongle detected. Request USB permission and approve the system prompt.';

  @override
  String get usbStatusPermissionDenied =>
      'USB permission was denied for the attached dongle. Request it again and approve the prompt.';

  @override
  String get usbStatusPermissionGranted =>
      'USB permission is granted. The dongle still needs to be initialized before it can send IR.';

  @override
  String get usbStatusOpenFailed =>
      'USB permission is granted, but the dongle could not be initialized. Reconnect it and try again.';

  @override
  String get usbStatusNoDevice => 'No supported USB IR dongle detected.';

  @override
  String get usbSelectPermissionRequired =>
      'USB dongle detected but not authorized. Tap \"Request USB permission\".';

  @override
  String get usbSelectPermissionDenied =>
      'USB permission was denied. Tap \"Request USB permission\" and approve the prompt.';

  @override
  String get usbSelectPermissionGranted =>
      'USB permission is granted, but the dongle is not initialized yet. Try reconnecting it.';

  @override
  String get usbSelectOpenFailed =>
      'USB permission is granted, but the dongle could not be initialized. Reconnect it and try again.';

  @override
  String get usbSelectNoDevice =>
      'No supported USB IR dongle detected. Plug it in, then tap \"Request USB permission\".';

  @override
  String get usbSelectReady => 'USB dongle is ready.';

  @override
  String get autoSwitchEnabledMessage =>
      'Auto-switch enabled: uses USB when connected, otherwise Internal.';

  @override
  String get autoSwitchDisabledMessage =>
      'Auto-switch disabled: transmitter selection is now manual.';

  @override
  String get failedToUpdateAutoSwitch =>
      'Failed to update auto-switch setting.';

  @override
  String get failedToSwitchTransmitter => 'Failed to switch transmitter.';

  @override
  String get deviceHasNoInternalIr => 'This device has no built-in IR emitter.';

  @override
  String get audioModeEnabledMessage =>
      'Audio mode enabled. Use max media volume and an audio-to-IR LED adapter.';

  @override
  String get usbPermissionRequestSent => 'USB permission request sent.';

  @override
  String get usbPermissionRequestSentApprove =>
      'USB permission request sent. Approve the prompt to enable USB.';

  @override
  String get usbAlreadyReady => 'USB dongle is already initialized and ready.';

  @override
  String get failedToRequestUsbPermission =>
      'Failed to request USB permission.';

  @override
  String get transmitterHelpInternal =>
      'Use the phone’s built-in IR emitter to send commands.';

  @override
  String get transmitterHelpUsb =>
      'Use a USB IR dongle (permission required) to send commands.';

  @override
  String get transmitterHelpAudio1 =>
      'Use audio output (mono). Requires an audio-to-IR LED adapter and high media volume.';

  @override
  String get transmitterHelpAudio2 =>
      'Use audio output (stereo). Uses two channels for improved LED driving with compatible adapters.';

  @override
  String get transmitterInternal => 'Internal IR';

  @override
  String get transmitterUsb => 'USB IR Dongle';

  @override
  String get transmitterAudio1 => 'Audio (1 LED)';

  @override
  String get transmitterAudio2 => 'Audio (2 LEDs)';

  @override
  String get failedToLoadTransmitterCapabilities =>
      'Failed to load transmitter capabilities.';

  @override
  String get selectedTransmitter => 'Selected transmitter';

  @override
  String selectedTransmitterValue(Object effective, Object active) {
    return '$effective • Active: $active';
  }

  @override
  String get refresh => 'Refresh';

  @override
  String get autoSwitchTitle => 'Auto-switch';

  @override
  String get autoSwitchDisabledWhileAudio => 'Disabled while using Audio mode';

  @override
  String get autoSwitchUsesUsbOtherwiseInternal =>
      'Uses USB when connected, otherwise Internal';

  @override
  String get unavailableOnThisDevice => 'Unavailable on this device';

  @override
  String get openOnUsbAttachTitle => 'Open on USB attach';

  @override
  String get openOnUsbAttachSubtitle =>
      'Android may suggest opening the app when a supported USB IR dongle is connected.';

  @override
  String get openOnUsbAttachEnabledMessage =>
      'Will suggest opening Everything-B-Gone when a supported USB dongle is attached.';

  @override
  String get openOnUsbAttachDisabledMessage =>
      'Won\'t suggest opening on USB attach.';

  @override
  String get failedToUpdateSetting => 'Failed to update setting.';

  @override
  String get skip => 'Skip';

  @override
  String get add => 'Add';

  @override
  String get edit => 'Edit';

  @override
  String get done => 'Done';

  @override
  String get remove => 'Remove';

  @override
  String get all => 'All';

  @override
  String get stop => 'Stop';

  @override
  String get brand => 'Brand';

  @override
  String get unknown => 'Unknown';

  @override
  String get deviceCodeLabel => 'Device Code';

  @override
  String get commandLabel => 'Command';

  @override
  String get editButtonCodeTitle => 'Edit Code of the button';

  @override
  String get test => 'Test';

  @override
  String get saveAction => 'Save';

  @override
  String get paused => 'Paused';

  @override
  String get running => 'Running';

  @override
  String get ready => 'Ready';

  @override
  String get error => 'Error';

  @override
  String get start => 'Start';

  @override
  String get resume => 'Resume';

  @override
  String get pause => 'Pause';

  @override
  String get showDeviceControlsOnHome => 'Show quick controls on home';

  @override
  String get showDeviceControlsOnHomeSubtitle =>
      'Show the compact Power, Mute, and Volume row on the main screen.';

  @override
  String get homeDeviceControlsShown => 'Quick controls shown on home.';

  @override
  String get homeDeviceControlsHidden => 'Quick controls hidden from home.';

  @override
  String get power => 'Power';

  @override
  String get mute => 'Mute';

  @override
  String get irWaveformTitle => 'IR waveform';

  @override
  String irWaveformPulseCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pulses',
      one: '$count pulse',
    );
    return '$_temp0';
  }

  @override
  String irWaveformGapLabel(String duration) {
    return 'Gap $duration';
  }

  @override
  String irWaveformDurationCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count durations',
      one: '$count duration',
    );
    return '$_temp0';
  }

  @override
  String get irWaveformActiveHint =>
      'High means the IR LED carrier is active; low means silence.';

  @override
  String get irWaveformOnLabel => 'ON';

  @override
  String get irWaveformOffLabel => 'OFF';

  @override
  String get quickSettingsTilesTitle => 'Quick Settings tiles';

  @override
  String get quickSettingsPowerTile => 'Power tile';

  @override
  String get quickSettingsMuteTile => 'Mute tile';
}
