import 'dart:async';
import 'package:flutter/material.dart';
import 'package:everythingbgone/config/build_flags.dart';
import 'package:everythingbgone/l10n/l10n.dart';
import 'package:everythingbgone/state/orientation_pref.dart';
import 'package:flutter/services.dart';
import 'package:everythingbgone/state/haptics.dart';
import 'package:everythingbgone/state/home_surface_prefs.dart';
import 'package:everythingbgone/state/app_theme.dart';
import 'package:everythingbgone/state/dynamic_color.dart';
import 'package:everythingbgone/state/remote_display_prefs.dart';
import 'package:everythingbgone/utils/ir_transmitter_platform.dart';
import 'package:everythingbgone/widgets/about_screen.dart';
import 'package:everythingbgone/widgets/settings/widgets/donation_sheet.dart';
import 'package:everythingbgone/widgets/settings/widgets/section_card.dart';
import 'package:everythingbgone/widgets/settings/widgets/support_pill.dart';
import 'package:everythingbgone/widgets/device_controls_screen.dart';
import 'package:everythingbgone/widgets/quick_settings_screen.dart';
import 'package:everythingbgone/widgets/settings/widgets/flipper_data_card.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const String _repoUrl = 'https://github.com/iodn/android-ir-blaster';
  static const String _issuesUrl =
      'https://github.com/iodn/android-ir-blaster/issues';
  static const String _licenseUrl =
      'https://github.com/iodn/android-ir-blaster/blob/master/LICENSE';
  static const String _companyUrl = 'https://neroswarm.com';
  static const String _creatorName = 'KaijinLab Inc.';
  static const String _liberapayUrl = 'https://liberapay.com/KaijinLab/donate';
  static const String _btcAddress =
      'bc1qtf79uecssueu4u4u86zct46vcs0vcd2cnmvw6f';
  static const String _ethAddress =
      '0xCaCc52Cd2D534D869a5C61dD3cAac57455f3c2fD';

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.noBrowserAvailable),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.failedToOpen(e.toString())),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyToClipboard(
    BuildContext context, {
    required String text,
    required String message,
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    await Haptics.selectionClick();
  }


  void _openDonationSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return FractionallySizedBox(
          heightFactor: 0.92,
          child: DonationSheet(
            repoUrl: _repoUrl,
            btcAddress: _btcAddress,
            ethAddress: _ethAddress,
            liberapayUrl: _liberapayUrl,
            onCopy: (text, message) =>
                _copyToClipboard(ctx, text: text, message: message),
          ),
        );
      },
    );
  }

  Future<void> _changeTheme(BuildContext context, ThemeMode mode) async {
    await AppThemeController.instance.setMode(mode);
    await Haptics.selectionClick();
  }

  String _getThemeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.l10n.themeAuto;
      case ThemeMode.light:
        return context.l10n.themeLight;
      case ThemeMode.dark:
        return context.l10n.themeDark;
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return Icons.auto_awesome_rounded;
      case ThemeMode.light:
        return Icons.light_mode_rounded;
      case ThemeMode.dark:
        return Icons.dark_mode_rounded;
    }
  }

  String _getThemeDescription(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.l10n.themeDescAuto;
      case ThemeMode.light:
        return context.l10n.themeDescLight;
      case ThemeMode.dark:
        return context.l10n.themeDescDark;
    }
  }

  String _getThemeHint(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return context.l10n.themeHintAuto;
      case ThemeMode.light:
        return context.l10n.themeHintLight;
      case ThemeMode.dark:
        return context.l10n.themeHintDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settingsTitle)),
      body: ListView(
        children: [
          const SizedBox(height: 10),
          if (BuildFlags.showDonations) ...[
            _buildSupportSection(context),
            const SizedBox(height: 10),
          ],
          _buildAppearanceSection(context),
          const SizedBox(height: 10),
          _buildInteractionSection(context),
          const SizedBox(height: 10),
          _buildIrTransmitterSection(context, cs),
          const SizedBox(height: 10),
          _buildFlipperDataSection(context, cs),
          const SizedBox(height: 10),
          _buildDeviceControlsSection(context),
          const SizedBox(height: 10),
          _buildQuickSettingsSection(context),
          const SizedBox(height: 10),
          _buildAboutSection(context),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  Widget _buildSupportSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: context.l10n.supportDevelopmentTitle,
        subtitle: context.l10n.supportDevelopmentSubtitle,
        leading: Icon(Icons.volunteer_activism_rounded, color: cs.primary),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.secondaryContainer.withValues(alpha: 0.7),
                      cs.secondaryContainer.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: cs.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Text(
                  context.l10n.supportDevelopmentBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openDonationSheet(context),
                      icon: const Icon(Icons.favorite_rounded),
                      label: Text(context.l10n.donate),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _launchUrl(context, _repoUrl),
                      onLongPress: () => _copyToClipboard(
                        context,
                        text: _repoUrl,
                        message: context.l10n.repositoryLinkCopied,
                      ),
                      icon: const Icon(Icons.star_border_rounded),
                      label: Text(context.l10n.starRepo),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  SupportPill(
                      icon: Icons.lock_outline_rounded,
                      label: context.l10n.supportPillLocalOnly),
                  SupportPill(
                      icon: Icons.shield_outlined,
                      label: context.l10n.supportPillNoTracking),
                  SupportPill(
                      icon: Icons.memory_rounded,
                      label: context.l10n.supportPillHardwareAware),
                  SupportPill(
                      icon: Icons.code_rounded,
                      label: context.l10n.supportPillOpenSource),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppearanceSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedBuilder(
        animation: AppThemeController.instance,
        builder: (context, _) {
          final mode = AppThemeController.instance.mode;

          return SectionCard(
            title: context.l10n.appearanceTitle,
            subtitle: context.l10n.appearanceSubtitle,
            leading: Icon(Icons.palette_outlined, color: cs.primary),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          cs.primaryContainer.withValues(alpha: 0.6),
                          cs.primaryContainer.withValues(alpha: 0.3),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: cs.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getThemeIcon(mode),
                            size: 20,
                            color: cs.onPrimary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getThemeName(context, mode),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _getThemeDescription(context, mode),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: cs.onPrimaryContainer
                                      .withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile.adaptive(
                    secondary: const Icon(Icons.wallpaper_rounded),
                    title: Text(context.l10n.useDynamicColors),
                    value: DynamicColorController.instance.enabled,
                    onChanged: (v) async {
                      await DynamicColorController.instance.setEnabled(v);
                      await Haptics.selectionClick();
                    },
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Icons.auto_awesome_rounded,
                          label: context.l10n.themeChoiceAuto,
                          isSelected: mode == ThemeMode.system,
                          onTap: () => _changeTheme(context, ThemeMode.system),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Icons.light_mode_rounded,
                          label: context.l10n.themeChoiceLight,
                          isSelected: mode == ThemeMode.light,
                          onTap: () => _changeTheme(context, ThemeMode.light),
                          theme: theme,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _ThemeOptionCard(
                          icon: Icons.dark_mode_rounded,
                          label: context.l10n.themeChoiceDark,
                          isSelected: mode == ThemeMode.dark,
                          onTap: () => _changeTheme(context, ThemeMode.dark),
                          theme: theme,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: cs.outlineVariant.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 16, color: cs.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getThemeHint(context, mode),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIrTransmitterSection(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: context.l10n.irTransmitterTitle,
        subtitle: context.l10n.irTransmitterSubtitle,
        leading: Icon(Icons.settings_input_antenna_rounded, color: cs.primary),
        titleSuffix: _buildSignalBadge(
          context,
          label: 'TX',
          foreground: cs.primary,
          background: cs.primaryContainer,
        ),
        child: const _IrTransmitterCard(),
      ),
    );
  }

  Widget _buildFlipperDataSection(BuildContext context, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: 'Flipper-IRDB data',
        subtitle: 'Manage the cached device signal database',
        leading: Icon(Icons.cloud_download_rounded, color: cs.primary),
        child: const FlipperDataCard(),
      ),
    );
  }

  Widget _buildSignalBadge(
    BuildContext context, {
    required String label,
    required Color foreground,
    required Color background,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildInteractionSection(BuildContext context) {
    final orientationCtrl = RemoteOrientationController.instance;
    final displayCtrl = RemoteDisplayController.instance;
    final cs = Theme.of(context).colorScheme;
    unawaited(HapticsController.instance.refreshDiagnostics(notify: false));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: context.l10n.interactionTitle,
        subtitle: context.l10n.interactionSubtitle,
        leading: Icon(Icons.vibration_rounded, color: cs.primary),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: HapticsController.instance,
              builder: (context, _) {
                final enabled = HapticsController.instance.enabled;
                final intensity =
                    HapticsController.instance.intensity.clamp(1, 3);
                final forceOverride =
                    HapticsController.instance.forceVibrationOverride;
                final diagnostics = HapticsController.instance.diagnostics;
                final forceBlocked =
                    forceOverride && diagnostics.forceOverrideLikelyBlocked;
                final forceBlockedMessage = switch (diagnostics.reasonCode) {
                  'no_vibrator' =>
                    context.l10n.forceInAppVibrationNoVibratorWarning,
                  'master_vibration_disabled' =>
                    context.l10n.forceInAppVibrationBlockedMasterWarning,
                  _ => context.l10n.forceInAppVibrationBlockedMasterWarning,
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.vibration_rounded),
                      title: Text(context.l10n.hapticFeedbackTitle),
                      subtitle: Text(context.l10n.hapticFeedbackSubtitle),
                      value: enabled,
                      onChanged: (v) =>
                          HapticsController.instance.setEnabled(v),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 56, right: 12, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.l10n.intensity,
                              style: Theme.of(context).textTheme.labelMedium),
                          const SizedBox(height: 6),
                          SegmentedButton<int>(
                            segments: [
                              ButtonSegment(
                                  value: 1,
                                  label: Text(context.l10n.intensityLight)),
                              ButtonSegment(
                                  value: 2,
                                  label: Text(context.l10n.intensityMedium)),
                              ButtonSegment(
                                  value: 3,
                                  label: Text(context.l10n.intensityStrong)),
                            ],
                            selected: <int>{intensity},
                            onSelectionChanged: enabled
                                ? (s) async {
                                    await HapticsController.instance
                                        .setIntensity(s.first);
                                    if (context.mounted) {
                                      await Haptics.mediumImpact();
                                    }
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                    SwitchListTile.adaptive(
                      secondary: const Icon(Icons.vibration_rounded),
                      title: Text(context.l10n.forceInAppVibrationTitle),
                      value: forceOverride,
                      onChanged: enabled
                          ? (v) async {
                              await HapticsController.instance
                                  .setForceVibrationOverride(v);
                              await HapticsController.instance
                                  .refreshDiagnostics();
                              if (!context.mounted) return;
                              final currentDiagnostics =
                                  HapticsController.instance.diagnostics;
                              if (v &&
                                  currentDiagnostics
                                      .forceOverrideLikelyBlocked) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      switch (currentDiagnostics.reasonCode) {
                                        'no_vibrator' => context.l10n
                                            .forceInAppVibrationNoVibratorWarning,
                                        'master_vibration_disabled' => context
                                            .l10n
                                            .forceInAppVibrationBlockedMasterWarning,
                                        _ => context.l10n
                                            .forceInAppVibrationBlockedMasterWarning,
                                      },
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else if (v) {
                                await Haptics.heavyImpact();
                              }
                            }
                          : null,
                    ),
                    if (forceBlocked)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(56, 0, 12, 8),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  size: 18, color: cs.onErrorContainer),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  forceBlockedMessage,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: cs.onErrorContainer,
                                        height: 1.3,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
            const Divider(height: 1),
            AnimatedBuilder(
              animation: orientationCtrl,
              builder: (context, _) {
                return AnimatedRotation(
                  turns: orientationCtrl.flipped ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOutCubic,
                  child: SwitchListTile.adaptive(
                    secondary: const Icon(Icons.screen_rotation_rounded),
                    title: Text(context.l10n.flipRemoteDefaultTitle),
                    subtitle: Text(context.l10n.flipRemoteDefaultSubtitle),
                    value: orientationCtrl.flipped,
                    onChanged: (v) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final l10n = context.l10n;
                      await orientationCtrl.setFlipped(v);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(v
                              ? l10n.remoteViewFlipped
                              : l10n.remoteViewNormal),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const Divider(height: 1),
            AnimatedBuilder(
              animation: displayCtrl,
              builder: (context, _) {
                return SwitchListTile.adaptive(
                  secondary: const Icon(Icons.view_agenda_outlined),
                  title: Text(context.l10n.remoteButtonMetadataTitle),
                  subtitle: Text(context.l10n.remoteButtonMetadataSubtitle),
                  value: displayCtrl.showButtonMetadata,
                  onChanged: (v) async {
                    final messenger = ScaffoldMessenger.of(context);
                    final l10n = context.l10n;
                    await displayCtrl.setShowButtonMetadata(v);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          v
                              ? l10n.remoteButtonMetadataShown
                              : l10n.remoteButtonMetadataHidden,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: context.l10n.aboutTitle,
        subtitle: context.l10n.aboutSubtitle,
        leading: Icon(Icons.info_outline, color: cs.primary),
        child: Column(
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final info = snapshot.data;
                final version =
                    info == null ? '—' : '${info.version}+${info.buildNumber}';
                return ListTile(
                  leading: const Icon(Icons.apps),
                  title:
                      Text(context.l10n.aboutAppNameWithCreator(_creatorName)),
                  subtitle: Text(context.l10n.versionLabel(version)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AboutScreen(
                          repoUrl: _repoUrl,
                          issuesUrl: _issuesUrl,
                          liberapayUrl:
                              BuildFlags.showDonations ? _liberapayUrl : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.code),
              title: Text(context.l10n.sourceCode),
              subtitle: Text(context.l10n.viewOnGitHub),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchUrl(context, _repoUrl),
              onLongPress: () => _copyToClipboard(context,
                  text: _repoUrl, message: context.l10n.repositoryUrlCopied),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.bug_report),
              title: Text(context.l10n.reportIssue),
              subtitle: Text(context.l10n.reportIssueSubtitle),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchUrl(context, _issuesUrl),
              onLongPress: () => _copyToClipboard(context,
                  text: _issuesUrl, message: context.l10n.issuesUrlCopied),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: Text(context.l10n.license),
              subtitle: Text(context.l10n.openSourceLicense),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchUrl(context, _licenseUrl),
              onLongPress: () => _copyToClipboard(context,
                  text: _licenseUrl, message: context.l10n.licenseUrlCopied),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.business),
              title: Text(context.l10n.companyName),
              subtitle: Text(context.l10n.visitWebsite),
              trailing: const Icon(Icons.open_in_new),
              onTap: () => _launchUrl(context, _companyUrl),
              onLongPress: () => _copyToClipboard(context,
                  text: _companyUrl, message: context.l10n.companyUrlCopied),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: Text(context.l10n.licenses),
              subtitle: Text(context.l10n.openSourceLicenses),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                showLicensePage(
                  context: context,
                  applicationName: context.l10n.appTitle,
                  applicationVersion: context.l10n.byCreator(_creatorName),
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Icon(Icons.settings_remote_rounded,
                        size: 48, color: cs.primary),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceControlsSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: context.l10n.deviceControlsTitle,
        subtitle: context.l10n.deviceControlsSubtitle,
        leading: Icon(Icons.tune_rounded, color: cs.primary),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.power_outlined),
              title: Text(context.l10n.manageFavorites),
              subtitle: Text(context.l10n.manageFavoritesSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const DeviceControlsScreen()),
                );
              },
            ),
            FutureBuilder<bool>(
              future: HomeSurfacePrefs.showDeviceControlsRow(),
              builder: (context, snapshot) {
                final value = snapshot.data ?? true;
                return SwitchListTile.adaptive(
                  secondary: const Icon(Icons.home_outlined),
                  title: Text(context.l10n.showDeviceControlsOnHome),
                  subtitle: Text(context.l10n.showDeviceControlsOnHomeSubtitle),
                  value: value,
                  onChanged: (next) async {
                    await HomeSurfacePrefs.setShowDeviceControlsRow(next);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          next
                              ? context.l10n.homeDeviceControlsShown
                              : context.l10n.homeDeviceControlsHidden,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSettingsSection(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SectionCard(
        title: context.l10n.quickSettingsTitle,
        subtitle: context.l10n.quickSettingsSubtitle,
        leading: Icon(Icons.view_quilt_rounded, color: cs.primary),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.tune_rounded),
              title: Text(context.l10n.configureTiles),
              subtitle: Text(context.l10n.configureTilesSubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const QuickSettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

}

class _ThemeOptionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ThemeOptionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withValues(alpha: 0.7)
              : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? cs.primary.withValues(alpha: 0.5)
                : cs.outlineVariant.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? cs.primary : cs.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? cs.onPrimary : cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 4),
              Icon(Icons.check_circle, size: 16, color: cs.primary),
            ],
          ],
        ),
      ),
    );
  }
}

class _IrTransmitterCard extends StatefulWidget {
  const _IrTransmitterCard();

  @override
  State<_IrTransmitterCard> createState() => _IrTransmitterCardState();
}

class _IrTransmitterCardState extends State<_IrTransmitterCard> {
  bool _loading = true;
  bool _busy = false;

  IrTransmitterType _preferred = IrTransmitterType.internal;
  IrTransmitterType _active = IrTransmitterType.internal;

  IrTransmitterCapabilities? _caps;
  bool _autoSwitchEnabled = false;
  bool _openOnUsbAttachEnabled = false;

  StreamSubscription<IrTransmitterCapabilities>? _capsSub;

  @override
  void initState() {
    super.initState();
    _capsSub = IrTransmitterPlatform.capabilitiesEvents().listen(
      (caps) {
        if (!mounted) return;

        final hasInternal = caps.hasInternal;
        final bool activeIsAudio =
            caps.currentType == IrTransmitterType.audio1Led ||
                caps.currentType == IrTransmitterType.audio2Led;
        final autoSwitch =
            (hasInternal && !activeIsAudio) ? caps.autoSwitchEnabled : false;

        setState(() {
          _caps = caps;
          _active = caps.currentType;
          _autoSwitchEnabled = autoSwitch;
          _loading = false;
        });

        if (!hasInternal && _preferred == IrTransmitterType.internal) {
          setState(() {
            _preferred = IrTransmitterType.usb;
          });
          unawaited(
              IrTransmitterPlatform.setPreferredType(IrTransmitterType.usb));
        }
      },
      onError: (_) {},
      cancelOnError: false,
    );

    _load();
  }

  @override
  void dispose() {
    _capsSub?.cancel();
    _capsSub = null;
    super.dispose();
  }

  IrTransmitterType _effectiveSelection(bool hasInternal) {
    final bool preferredIsAudio = _preferred == IrTransmitterType.audio1Led ||
        _preferred == IrTransmitterType.audio2Led;
    final bool activeIsAudio = _active == IrTransmitterType.audio1Led ||
        _active == IrTransmitterType.audio2Led;
    if (preferredIsAudio || activeIsAudio) return _preferred;
    if (hasInternal && _autoSwitchEnabled) return _active;
    return _preferred;
  }

  Future<void> _load({bool showErrors = false}) async {
    try {
      final preferred = await IrTransmitterPlatform.getPreferredType();
      final caps = await IrTransmitterPlatform.getCapabilities();

      bool autoSwitch = false;
      bool openOnUsbAttach = false;

      try {
        autoSwitch = await IrTransmitterPlatform.getAutoSwitchEnabled();
      } catch (_) {
        autoSwitch = caps.autoSwitchEnabled;
      }

      try {
        openOnUsbAttach =
            await IrTransmitterPlatform.getOpenOnUsbAttachEnabled();
      } catch (_) {}

      if (!mounted) return;

      IrTransmitterType effectivePreferred = preferred;
      final bool activeIsAudio =
          caps.currentType == IrTransmitterType.audio1Led ||
              caps.currentType == IrTransmitterType.audio2Led;
      bool effectiveAuto =
          (caps.hasInternal && !activeIsAudio) ? autoSwitch : false;

      if (!caps.hasInternal) {
        if (effectivePreferred == IrTransmitterType.internal) {
          effectivePreferred = IrTransmitterType.usb;
          try {
            await IrTransmitterPlatform.setPreferredType(IrTransmitterType.usb);
          } catch (_) {}
        }
        if (effectiveAuto) {
          effectiveAuto = false;
          try {
            await IrTransmitterPlatform.setAutoSwitchEnabled(false);
          } catch (_) {}
        }
      }

      setState(() {
        _preferred = effectivePreferred;
        _caps = caps;
        _active = caps.currentType;
        _autoSwitchEnabled = effectiveAuto;
        _openOnUsbAttachEnabled = openOnUsbAttach;
        _loading = false;
        _busy = false;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _busy = false;
      });
      if (showErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  e.message ?? context.l10n.failedToLoadTransmitterSettings)),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _busy = false;
      });
      if (showErrors) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.failedToLoadTransmitterSettings)),
        );
      }
    }
  }

  Future<void> _refreshCaps() async {
    try {
      final caps = await IrTransmitterPlatform.getCapabilities();
      bool autoSwitch = _autoSwitchEnabled;

      try {
        autoSwitch = await IrTransmitterPlatform.getAutoSwitchEnabled();
      } catch (_) {
        autoSwitch = caps.autoSwitchEnabled;
      }

      if (!mounted) return;

      final bool activeIsAudio =
          caps.currentType == IrTransmitterType.audio1Led ||
              caps.currentType == IrTransmitterType.audio2Led;
      setState(() {
        _caps = caps;
        _active = caps.currentType;
        _autoSwitchEnabled =
            (caps.hasInternal && !activeIsAudio) ? autoSwitch : false;
      });
    } catch (_) {}
  }

  String _usbStatusBannerText(
      BuildContext context, IrTransmitterCapabilities caps) {
    switch (caps.usbStatus) {
      case UsbConnectionStatus.ready:
        return context.l10n.usbStatusReady;
      case UsbConnectionStatus.permissionRequired:
        return context.l10n.usbStatusPermissionRequired;
      case UsbConnectionStatus.permissionDenied:
        return context.l10n.usbStatusPermissionDenied;
      case UsbConnectionStatus.permissionGranted:
        return context.l10n.usbStatusPermissionGranted;
      case UsbConnectionStatus.openFailed:
        return caps.usbStatusMessage ?? context.l10n.usbStatusOpenFailed;
      case UsbConnectionStatus.noDevice:
        return context.l10n.usbStatusNoDevice;
    }
  }

  String _usbSelectionMessage(
      BuildContext context, IrTransmitterCapabilities caps) {
    switch (caps.usbStatus) {
      case UsbConnectionStatus.permissionRequired:
        return context.l10n.usbSelectPermissionRequired;
      case UsbConnectionStatus.permissionDenied:
        return context.l10n.usbSelectPermissionDenied;
      case UsbConnectionStatus.permissionGranted:
        return context.l10n.usbSelectPermissionGranted;
      case UsbConnectionStatus.openFailed:
        return caps.usbStatusMessage ?? context.l10n.usbSelectOpenFailed;
      case UsbConnectionStatus.noDevice:
        return context.l10n.usbSelectNoDevice;
      case UsbConnectionStatus.ready:
        return context.l10n.usbSelectReady;
    }
  }

  Future<void> _setAutoSwitch(bool enabled) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final caps = _caps;
    if (caps == null) return;

    final bool activeIsAudio = _active == IrTransmitterType.audio1Led ||
        _active == IrTransmitterType.audio2Led;
    if (activeIsAudio) enabled = false;
    if (!caps.hasInternal && enabled) enabled = false;

    setState(() {
      _busy = true;
      _autoSwitchEnabled = enabled;
    });

    try {
      await IrTransmitterPlatform.setAutoSwitchEnabled(enabled);
      await _refreshCaps();

      if (!mounted) return;

      if (enabled) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.autoSwitchEnabledMessage)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.autoSwitchDisabledMessage)),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateAutoSwitch)),
        );
      }
    }

    await _refreshCaps();
    if (!mounted) return;
    setState(() {
      _busy = false;
    });
  }

  Future<void> _setOpenOnUsbAttach(bool value) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    setState(() {
      _busy = true;
      _openOnUsbAttachEnabled = value;
    });

    try {
      final ok = await IrTransmitterPlatform.setOpenOnUsbAttachEnabled(value);
      if (!mounted) return;
      setState(() {
        _openOnUsbAttachEnabled = ok;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(ok
              ? l10n.openOnUsbAttachEnabledMessage
              : l10n.openOnUsbAttachDisabledMessage),
        ),
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.failedToUpdateSetting)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _applyManualSelection(IrTransmitterType t) async {
    final caps = _caps;
    if (caps != null && !caps.hasInternal && t == IrTransmitterType.internal) {
      return;
    }

    final bool selectedIsAudio =
        t == IrTransmitterType.audio1Led || t == IrTransmitterType.audio2Led;
    final bool turningOffAutoNow = (_autoSwitchEnabled &&
        (selectedIsAudio ||
            t == IrTransmitterType.internal ||
            t == IrTransmitterType.usb));

    setState(() {
      _busy = true;
      _preferred = t;
      if (turningOffAutoNow) _autoSwitchEnabled = false;
    });

    try {
      await IrTransmitterPlatform.setPreferredType(t);
    } catch (_) {}

    if (turningOffAutoNow) {
      try {
        await IrTransmitterPlatform.setAutoSwitchEnabled(false);
      } catch (_) {}
    }

    try {
      await IrTransmitterPlatform.setActiveType(t);
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.message ?? context.l10n.failedToSwitchTransmitter)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.failedToSwitchTransmitter)),
      );
    } finally {
      await _refreshCaps();
    }

    if (!mounted) return;
    final freshCaps = _caps;

    if (t == IrTransmitterType.usb &&
        freshCaps != null &&
        !freshCaps.usbReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_usbSelectionMessage(context, freshCaps))),
      );
    }

    if (t == IrTransmitterType.internal &&
        freshCaps != null &&
        !freshCaps.hasInternal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.deviceHasNoInternalIr)),
      );
    }

    if (selectedIsAudio) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.audioModeEnabledMessage)),
      );
    }

    setState(() {
      _busy = false;
    });
  }

  Future<void> _requestUsbPermission() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() {
      _busy = true;
    });

    try {
      final ok = await IrTransmitterPlatform.usbScanAndRequest();
      await _refreshCaps();
      if (!mounted) return;

      final freshCaps = _caps;

      if (!ok) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.homeUsbDongleNotDetected)),
        );
      } else if (freshCaps == null) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.usbPermissionRequestSent)),
        );
      } else if (freshCaps.usbStatus ==
              UsbConnectionStatus.permissionRequired ||
          freshCaps.usbStatus == UsbConnectionStatus.permissionDenied) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.usbPermissionRequestSentApprove)),
        );
      } else if (freshCaps.usbStatus == UsbConnectionStatus.ready) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.usbAlreadyReady)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(_usbStatusBannerText(context, freshCaps))),
        );
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.failedToRequestUsbPermission)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  String _helpTextFor(BuildContext context, IrTransmitterType t) {
    switch (t) {
      case IrTransmitterType.internal:
        return context.l10n.transmitterHelpInternal;
      case IrTransmitterType.usb:
        return context.l10n.transmitterHelpUsb;
      case IrTransmitterType.audio1Led:
        return context.l10n.transmitterHelpAudio1;
      case IrTransmitterType.audio2Led:
        return context.l10n.transmitterHelpAudio2;
    }
  }

  String _titleFor(BuildContext context, IrTransmitterType t) {
    switch (t) {
      case IrTransmitterType.internal:
        return context.l10n.transmitterInternal;
      case IrTransmitterType.usb:
        return context.l10n.transmitterUsb;
      case IrTransmitterType.audio1Led:
        return context.l10n.transmitterAudio1;
      case IrTransmitterType.audio2Led:
        return context.l10n.transmitterAudio2;
    }
  }

  IconData _iconFor(IrTransmitterType t) {
    switch (t) {
      case IrTransmitterType.internal:
        return Icons.settings_input_antenna_rounded;
      case IrTransmitterType.usb:
        return Icons.usb_rounded;
      case IrTransmitterType.audio1Led:
        return Icons.volume_up_rounded;
      case IrTransmitterType.audio2Led:
        return Icons.surround_sound_rounded;
    }
  }

  bool _availableFor(IrTransmitterType t, IrTransmitterCapabilities caps) {
    switch (t) {
      case IrTransmitterType.internal:
        return caps.hasInternal;
      case IrTransmitterType.usb:
        return caps.hasUsb;
      case IrTransmitterType.audio1Led:
      case IrTransmitterType.audio2Led:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(18),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final caps = _caps;
    if (caps == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(context.l10n.failedToLoadTransmitterCapabilities,
                style: TextStyle(color: cs.onSurfaceVariant)),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: _busy ? null : () => _load(showErrors: true),
              icon: const Icon(Icons.refresh_rounded),
              label: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    final effective = _effectiveSelection(caps.hasInternal);
    final active = _active;
    final bool activeIsAudio = active == IrTransmitterType.audio1Led ||
        active == IrTransmitterType.audio2Led;

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_iconFor(effective), color: cs.primary),
            title: Text(context.l10n.selectedTransmitter),
            subtitle: Text(
              context.l10n.selectedTransmitterValue(
                _titleFor(context, effective),
                _titleFor(context, active),
              ),
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            trailing: IconButton(
              tooltip: context.l10n.refresh,
              onPressed: _busy ? null : _refreshCaps,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ),
          const Divider(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _autoSwitchEnabled,
            onChanged: (_busy || !caps.hasInternal || activeIsAudio)
                ? null
                : (v) => _setAutoSwitch(v),
            title: Text(context.l10n.autoSwitchTitle),
            subtitle: Text(
              activeIsAudio
                  ? context.l10n.autoSwitchDisabledWhileAudio
                  : (caps.hasInternal
                      ? context.l10n.autoSwitchUsesUsbOtherwiseInternal
                      : context.l10n.unavailableOnThisDevice),
            ),
          ),
          const Divider(height: 18),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _openOnUsbAttachEnabled,
            onChanged: _busy ? null : _setOpenOnUsbAttach,
            title: Text(context.l10n.openOnUsbAttachTitle),
            subtitle: Text(context.l10n.openOnUsbAttachSubtitle),
          ),
          const Divider(height: 18),
          for (final t in IrTransmitterType.values) ...[
            _TransmitterOptionTile(
              type: t,
              title: _titleFor(context, t),
              subtitle: _helpTextFor(context, t),
              icon: _iconFor(t),
              selected: effective == t,
              enabled: !_busy && _availableFor(t, caps),
              onTap: () => _applyManualSelection(t),
            ),
            if (t != IrTransmitterType.values.last) const Divider(height: 1),
          ],
          if (effective == IrTransmitterType.usb) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 18, color: cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _usbStatusBannerText(context, caps),
                      style: TextStyle(color: cs.onSurfaceVariant, height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _requestUsbPermission,
                icon: const Icon(Icons.usb_rounded),
                label: Text(context.l10n.requestUsbPermission),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TransmitterOptionTile extends StatelessWidget {
  final IrTransmitterType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  const _TransmitterOptionTile({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected
            ? Icons.radio_button_checked_rounded
            : Icons.radio_button_off_rounded,
      ),
      onTap: enabled ? onTap : null,
    );
  }
}
