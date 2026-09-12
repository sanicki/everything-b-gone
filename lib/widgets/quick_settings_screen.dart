import 'package:flutter/material.dart';
import 'package:everythingbgone/l10n/l10n.dart';

/// Quick Settings tiles are fixed to Power and Mute: each tile fires the
/// app's kill-switch cycle directly from the notification shade, using
/// whatever Device Type / Brand filter is currently saved. There is no
/// per-tile "pick a button" binding anymore, so this screen is just
/// instructions for adding the tiles rather than a configuration UI.
class QuickSettingsScreen extends StatelessWidget {
  const QuickSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.quickSettingsTilesTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.tune_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.quickSettingsTilesTitle,
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.power_settings_new_rounded,
                        color: cs.primary),
                    title: Text(context.l10n.quickSettingsPowerTile),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.volume_off_rounded, color: cs.primary),
                    title: Text(context.l10n.quickSettingsMuteTile),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Both tiles fire the same Power/Mute kill-switch cycle as '
                    "the app's main buttons, transmitting every matching "
                    'signal for your current Device Type / Brand filter. '
                    'Add them from the pencil (edit tiles) icon in your '
                    "notification shade — they don't need to be set up here.",
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
