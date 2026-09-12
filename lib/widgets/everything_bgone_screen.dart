import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:everythingbgone/flipper_irdb/filter_logic.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';
import 'package:everythingbgone/flipper_irdb/kill_switch_data_controller.dart';
import 'package:everythingbgone/ir/flipper_signal_sender.dart';
import 'package:everythingbgone/ir/transmit_cycle_controller.dart';
import 'package:everythingbgone/state/orientation_pref.dart';
import 'package:everythingbgone/state/remote_display_prefs.dart';
import 'package:everythingbgone/widgets/kill_switch_common.dart';

/// The app's home screen: pick a Device Type / Brand filter, then blast
/// every matching Power (or Mute) signal from the cached Flipper-IRDB data.
class EverythingBGoneScreen extends StatefulWidget {
  const EverythingBGoneScreen({super.key});

  @override
  State<EverythingBGoneScreen> createState() => _EverythingBGoneScreenState();
}

class _EverythingBGoneScreenState extends State<EverythingBGoneScreen> {
  final KillSwitchDataController _data = KillSwitchDataController.instance;
  late final TransmitCycleController<FlipperIrSignal> _powerController;
  late final TransmitCycleController<FlipperIrSignal> _muteController;

  @override
  void initState() {
    super.initState();
    _powerController =
        TransmitCycleController<FlipperIrSignal>(sendCandidate: transmitFlipperSignal);
    _muteController =
        TransmitCycleController<FlipperIrSignal>(sendCandidate: transmitFlipperSignal);
    _powerController.addListener(_onChanged);
    _muteController.addListener(_onChanged);
    _data.addListener(_onChanged);
    unawaited(_data.ensureBootstrapped());
  }

  @override
  void dispose() {
    _data.removeListener(_onChanged);
    _powerController.removeListener(_onChanged);
    _muteController.removeListener(_onChanged);
    _powerController.dispose();
    _muteController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickDeviceTypes() async {
    final result = await showFilterMultiSelectSheet(
      context: context,
      title: 'Device type',
      options: _data.visibleDeviceTypeOptions,
      selected: _data.selectedDeviceTypes,
    );
    if (result != null) {
      await _data.updateSelection(deviceTypes: result);
    }
  }

  Future<void> _pickBrands() async {
    final result = await showFilterMultiSelectSheet(
      context: context,
      title: 'Brands',
      options: _data.visibleBrandOptions,
      selected: _data.selectedBrands,
    );
    if (result != null) {
      await _data.updateSelection(brands: result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Everything-B-Gone')),
      body: AnimatedBuilder(
        animation: RemoteOrientationController.instance,
        builder: (context, child) {
          return Transform.rotate(
            angle: RemoteOrientationController.instance.flipped ? math.pi : 0,
            child: child,
          );
        },
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    switch (_data.state) {
      case KillSwitchLoadState.loading:
        return const KillSwitchLoadingBody();
      case KillSwitchLoadState.error:
        return KillSwitchErrorBody(message: _data.errorMessage, onRetry: _data.retry);
      case KillSwitchLoadState.ready:
        return _buildReadyBody(context);
    }
  }

  Widget _buildReadyBody(BuildContext context) {
    final filtered = _data.filteredFiles;
    final powerSignals = matchingPowerSignals(filtered);
    final muteSignals = matchingMuteSignals(filtered);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_data.hasReadyTransmitter) const NoTransmitterBanner(),
        FilterField(
          label: 'Device type',
          value: summaryForSelection(_data.selectedDeviceTypes),
          onTap: _pickDeviceTypes,
        ),
        const SizedBox(height: 10),
        FilterField(
          label: 'Brands',
          value: summaryForSelection(_data.selectedBrands),
          onTap: _pickBrands,
        ),
        const SizedBox(height: 28),
        if (_data.loadingSelection)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty || (powerSignals.isEmpty && muteSignals.isEmpty))
          const NoMatchesMessage()
        else
          AnimatedBuilder(
            animation: RemoteDisplayController.instance,
            builder: (context, _) => _ActionArea(
              powerSignals: powerSignals,
              muteSignals: muteSignals,
              powerController: _powerController,
              muteController: _muteController,
              showSignalCounts: RemoteDisplayController.instance.showButtonMetadata,
              hasTransmitter: _data.hasReadyTransmitter,
            ),
          ),
      ],
    );
  }
}

class _ActionArea extends StatelessWidget {
  final List<FlipperIrSignal> powerSignals;
  final List<FlipperIrSignal> muteSignals;
  final TransmitCycleController<FlipperIrSignal> powerController;
  final TransmitCycleController<FlipperIrSignal> muteController;
  final bool showSignalCounts;
  final bool hasTransmitter;

  const _ActionArea({
    required this.powerSignals,
    required this.muteSignals,
    required this.powerController,
    required this.muteController,
    required this.showSignalCounts,
    required this.hasTransmitter,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        if (powerSignals.isNotEmpty)
          _CycleControl(
            label: 'POWER',
            signals: powerSignals,
            controller: powerController,
            otherRunning: muteController.running,
            color: cs.primary,
            onColor: cs.onPrimary,
            big: true,
            showSignalCount: showSignalCounts,
            hasTransmitter: hasTransmitter,
          ),
        if (powerSignals.isNotEmpty && muteSignals.isNotEmpty) const SizedBox(height: 20),
        if (muteSignals.isNotEmpty)
          _CycleControl(
            label: 'MUTE',
            signals: muteSignals,
            controller: muteController,
            otherRunning: powerController.running,
            color: cs.secondaryContainer,
            onColor: cs.onSecondaryContainer,
            big: false,
            showSignalCount: showSignalCounts,
            hasTransmitter: hasTransmitter,
          ),
      ],
    );
  }
}

class _CycleControl extends StatelessWidget {
  final String label;
  final List<FlipperIrSignal> signals;
  final TransmitCycleController<FlipperIrSignal> controller;
  final bool otherRunning;
  final Color color;
  final Color onColor;
  final bool big;
  final bool showSignalCount;
  final bool hasTransmitter;

  const _CycleControl({
    required this.label,
    required this.signals,
    required this.controller,
    required this.otherRunning,
    required this.color,
    required this.onColor,
    required this.big,
    required this.showSignalCount,
    required this.hasTransmitter,
  });

  Widget _circle({
    required VoidCallback? onPressed,
    required Color background,
    required Color foreground,
    required Widget child,
  }) {
    // Only force the custom colors while enabled — leaving them null when
    // disabled lets FilledButton fall back to Material's standard greyed-out
    // disabled treatment instead of always painting at full color.
    final enabled = onPressed != null;
    return SizedBox(
      width: 160,
      height: 160,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: enabled ? background : null,
          foregroundColor: enabled ? foreground : null,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final running = controller.running;

    if (running) {
      final progressBar = SizedBox(
        width: 220,
        child: LinearProgressIndicator(
          value: controller.total == 0 ? null : controller.attempted / controller.total,
        ),
      );

      if (big) {
        // Match the color FilledButton.tonalIcon used for the pill this
        // circle replaces while running, instead of the idle primary color.
        final cs = Theme.of(context).colorScheme;
        return Column(
          children: [
            _circle(
              onPressed: controller.stop,
              background: cs.secondaryContainer,
              foreground: cs.onSecondaryContainer,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.stop_rounded, size: 40),
                  const SizedBox(height: 4),
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  if (showSignalCount)
                    Text('${controller.attempted}/${controller.total}',
                        style: const TextStyle(fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            progressBar,
          ],
        );
      }

      final stopLabel = showSignalCount
          ? 'Stop — $label (${controller.attempted}/${controller.total})'
          : 'Stop — $label';
      return Column(
        children: [
          FilledButton.tonalIcon(
            onPressed: controller.stop,
            icon: const Icon(Icons.stop_rounded),
            label: Text(stopLabel),
          ),
          const SizedBox(height: 8),
          progressBar,
        ],
      );
    }

    final onPressed = (otherRunning || !hasTransmitter)
        ? null
        : () => controller.start(signals, delayMs: 700);

    if (big) {
      return _circle(
        onPressed: onPressed,
        background: color,
        foreground: onColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.power_settings_new_rounded, size: 40),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (showSignalCount)
              Text('${signals.length} signal${signals.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 11)),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.volume_off_rounded),
      label: Text(showSignalCount ? '$label (${signals.length})' : label),
    );
  }
}
