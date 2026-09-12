import 'package:flutter/material.dart';
import 'package:everythingbgone/l10n/l10n.dart';

/// Android Device Controls now exposes exactly two fixed controls — Power
/// and Mute — that fire the app's kill-switch cycle directly from the
/// lock screen / power menu's Device Controls panel. There is no more
/// per-slot "pick a remote+button" binding, so this screen is just
/// instructions rather than a configuration UI.
class DeviceControlsScreen extends StatelessWidget {
  const DeviceControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.deviceControlsTitle)),
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
                      Icon(Icons.settings_remote_rounded, color: cs.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.l10n.deviceControlsTitle,
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
                    title: const Text('Power'),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        Icon(Icons.volume_off_rounded, color: cs.primary),
                    title: const Text('Mute'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Both controls fire the same Power/Mute kill-switch '
                    "cycle as the app's main buttons, transmitting every "
                    'matching signal for your current Device Type / Brand '
                    'filter. Add them from the pencil (edit controls) icon '
                    "in Android's Device Controls panel — they don't need "
                    'to be set up here.',
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
