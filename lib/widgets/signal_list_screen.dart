import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:everythingbgone/flipper_irdb/filter_logic.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';
import 'package:everythingbgone/flipper_irdb/kill_switch_data_controller.dart';
import 'package:everythingbgone/ir/flipper_signal_sender.dart';
import 'package:everythingbgone/state/orientation_pref.dart';
import 'package:everythingbgone/widgets/kill_switch_common.dart';

/// Lets the user browse every signal matching their current Device Type /
/// Brand filter and fire Power or Mute for any single one by hand — for
/// manually checking a signal rather than blasting the whole cycle.
class SignalListScreen extends StatefulWidget {
  const SignalListScreen({super.key});

  @override
  State<SignalListScreen> createState() => _SignalListScreenState();
}

class _SignalListScreenState extends State<SignalListScreen> {
  final KillSwitchDataController _data = KillSwitchDataController.instance;

  @override
  void initState() {
    super.initState();
    _data.addListener(_onChanged);
    unawaited(_data.ensureBootstrapped());
  }

  @override
  void dispose() {
    _data.removeListener(_onChanged);
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

  Future<void> _send(FlipperIrSignal signal) async {
    try {
      await transmitFlipperSignal(signal);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send "${signal.name}": $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('List')),
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
    final groups = buildSignalListGroups(_data.filteredFiles);

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
        const SizedBox(height: 20),
        if (_data.loadingSelection)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (groups.isEmpty)
          const NoMatchesMessage()
        else
          ...groups.map((group) => _DeviceTypeSection(
                group: group,
                expandInitially: groups.length == 1,
                hasTransmitter: _data.hasReadyTransmitter,
                onSend: _send,
              )),
      ],
    );
  }
}

class _DeviceTypeSection extends StatelessWidget {
  final SignalListGroup group;
  final bool expandInitially;
  final bool hasTransmitter;
  final Future<void> Function(FlipperIrSignal signal) onSend;

  const _DeviceTypeSection({
    required this.group,
    required this.expandInitially,
    required this.hasTransmitter,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: expandInitially,
          title: Text(group.deviceType, style: const TextStyle(fontWeight: FontWeight.bold)),
          trailing: Text(
            '${group.rows.length}',
            style: TextStyle(color: cs.onSurfaceVariant),
          ),
          children: [
            for (final row in group.rows)
              _SignalRow(row: row, hasTransmitter: hasTransmitter, onSend: onSend),
          ],
        ),
      ),
    );
  }
}

class _SignalRow extends StatelessWidget {
  final SignalListRow row;
  final bool hasTransmitter;
  final Future<void> Function(FlipperIrSignal signal) onSend;

  const _SignalRow({required this.row, required this.hasTransmitter, required this.onSend});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 12, 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(row.brand, maxLines: 2, overflow: TextOverflow.ellipsis),
                if (row.optionLabel != null)
                  Text(
                    '(${row.optionLabel})',
                    style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Mute',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: (row.muteSignal != null && hasTransmitter)
                ? () => onSend(row.muteSignal!)
                : null,
            icon: const Icon(Icons.volume_off_rounded),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: 'Power',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: (row.powerSignal != null && hasTransmitter)
                ? () => onSend(row.powerSignal!)
                : null,
            icon: const Icon(Icons.power_settings_new_rounded),
          ),
        ],
      ),
    );
  }
}
