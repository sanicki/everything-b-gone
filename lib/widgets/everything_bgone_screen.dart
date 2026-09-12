import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:everythingbgone/flipper_irdb/filter_logic.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_service.dart';
import 'package:everythingbgone/flipper_irdb/kill_switch_prefs.dart';
import 'package:everythingbgone/ir/ir_protocol_registry.dart';
import 'package:everythingbgone/ir/transmit_cycle_controller.dart';
import 'package:everythingbgone/state/orientation_pref.dart';
import 'package:everythingbgone/state/remote_display_prefs.dart';
import 'package:everythingbgone/utils/ir.dart';
import 'package:everythingbgone/utils/ir_transmitter_platform.dart';

enum _LoadState { loading, error, ready }

/// The app's home screen: pick a Device Type / Brand filter, then blast
/// every matching Power (or Mute) signal from the cached Flipper-IRDB data.
class EverythingBGoneScreen extends StatefulWidget {
  const EverythingBGoneScreen({super.key});

  @override
  State<EverythingBGoneScreen> createState() => _EverythingBGoneScreenState();
}

class _EverythingBGoneScreenState extends State<EverythingBGoneScreen> {
  final FlipperIrdbService _service = FlipperIrdbService();
  late final TransmitCycleController<FlipperIrSignal> _powerController;
  late final TransmitCycleController<FlipperIrSignal> _muteController;

  _LoadState _state = _LoadState.loading;
  String _errorMessage = '';

  FlipperIrdbTree? _tree;
  FlipperQualification? _qualification;
  final Map<String, List<FlipperIrFile>> _loadedFiles = <String, List<FlipperIrFile>>{};
  final Set<String> _loadingTypes = <String>{};

  Set<String> _selectedDeviceTypes = <String>{'TVs'};
  Set<String> _selectedBrands = <String>{};

  IrTransmitterCapabilities? _capabilities;
  StreamSubscription<IrTransmitterCapabilities>? _capsSub;

  static Future<void> _sendSignal(FlipperIrSignal signal) async {
    if (signal.isRaw) {
      final pattern = signal.rawData!
          .trim()
          .split(RegExp(r'\s+'))
          .map(int.parse)
          .toList(growable: false);
      await transmitRaw(signal.frequencyHz ?? 38000, pattern);
      return;
    }
    final encoder = IrProtocolRegistry.encoderFor(signal.protocol!);
    final result =
        encoder.encode(signal.protocolParams ?? const <String, dynamic>{});
    await transmitRaw(result.frequencyHz, result.pattern);
  }

  @override
  void initState() {
    super.initState();
    _powerController = TransmitCycleController<FlipperIrSignal>(sendCandidate: _sendSignal);
    _muteController = TransmitCycleController<FlipperIrSignal>(sendCandidate: _sendSignal);
    _powerController.addListener(_onCycleChanged);
    _muteController.addListener(_onCycleChanged);
    _capsSub = IrTransmitterPlatform.capabilitiesEvents().listen(
      (caps) {
        if (!mounted) return;
        setState(() {
          _capabilities = caps;
        });
      },
      onError: (_) {},
      cancelOnError: false,
    );
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _capsSub?.cancel();
    _capsSub = null;
    _powerController.removeListener(_onCycleChanged);
    _muteController.removeListener(_onCycleChanged);
    _powerController.dispose();
    _muteController.dispose();
    super.dispose();
  }

  void _onCycleChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _bootstrap() async {
    setState(() {
      _state = _LoadState.loading;
    });

    try {
      _capabilities = await IrTransmitterPlatform.getCapabilities();
    } catch (_) {
      _capabilities = null;
    }

    final savedTypes = await KillSwitchFilterPrefs.loadDeviceTypes();
    final savedBrands = await KillSwitchFilterPrefs.loadBrands();
    if (savedTypes.isNotEmpty) _selectedDeviceTypes = savedTypes;
    _selectedBrands = savedBrands;

    _qualification = await _service.loadQualification();

    try {
      _tree = await _service.fetchTree();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _LoadState.error;
        _errorMessage = e.toString();
      });
      return;
    }

    await _ensureFilesLoadedForSelection();
    if (!mounted) return;
    setState(() {
      _state = _LoadState.ready;
    });

    unawaited(_runQualificationScanInBackground());
  }

  Future<void> _ensureFilesLoadedForSelection() async {
    final tree = _tree;
    if (tree == null) return;
    final types =
        _selectedDeviceTypes.isEmpty ? tree.deviceTypes : _selectedDeviceTypes.toList();
    for (final type in types) {
      if (_loadedFiles.containsKey(type) || _loadingTypes.contains(type)) continue;
      _loadingTypes.add(type);
      if (mounted) setState(() {});
      try {
        _loadedFiles[type] = await _service.fetchDeviceTypeFiles(type, tree);
      } catch (_) {
        _loadedFiles[type] = const <FlipperIrFile>[];
      } finally {
        _loadingTypes.remove(type);
      }
    }
    if (mounted) setState(() {});
  }

  Future<void> _runQualificationScanInBackground() async {
    final tree = _tree;
    if (tree == null) return;
    try {
      final firstType =
          _selectedDeviceTypes.isNotEmpty ? _selectedDeviceTypes.first : null;
      final qualification = await _service.runQualificationScan(
        tree,
        skip: firstType,
        skipFiles: firstType != null ? _loadedFiles[firstType] : null,
      );
      if (!mounted) return;
      setState(() {
        _qualification = qualification;
      });
    } catch (_) {
      // Best-effort: filters just stay unfiltered by qualification if this fails.
    }
  }

  List<FlipperIrFile> get _allLoadedFiles {
    final all = <FlipperIrFile>[];
    for (final files in _loadedFiles.values) {
      all.addAll(files);
    }
    return all;
  }

  List<FlipperIrFile> get _filteredFiles => filterFiles(
        _allLoadedFiles,
        FilterSelection(deviceTypes: _selectedDeviceTypes, brands: _selectedBrands),
      );

  List<String> get _visibleDeviceTypeOptions {
    final tree = _tree;
    if (tree == null) return const <String>[];
    final qualification = _qualification;
    if (qualification == null) return tree.deviceTypes;
    return visibleDeviceTypes(tree, qualification);
  }

  List<String> get _visibleBrandOptions {
    final tree = _tree;
    if (tree == null) return const <String>[];
    final types =
        _selectedDeviceTypes.isEmpty ? tree.deviceTypes : _selectedDeviceTypes.toList();
    final qualification = _qualification;
    final set = <String>{};
    for (final type in types) {
      set.addAll(
        qualification == null ? tree.brandsFor(type) : visibleBrands(tree, qualification, type),
      );
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<void> _updateSelection({Set<String>? deviceTypes, Set<String>? brands}) async {
    setState(() {
      if (deviceTypes != null) _selectedDeviceTypes = deviceTypes;
      if (brands != null) _selectedBrands = brands;
    });
    await KillSwitchFilterPrefs.save(
      deviceTypes: _selectedDeviceTypes,
      brands: _selectedBrands,
    );
    await _ensureFilesLoadedForSelection();
  }

  Future<void> _pickDeviceTypes() async {
    final result = await _showMultiSelectSheet(
      title: 'Device type',
      options: _visibleDeviceTypeOptions,
      selected: _selectedDeviceTypes,
    );
    if (result != null) {
      await _updateSelection(deviceTypes: result);
    }
  }

  Future<void> _pickBrands() async {
    final result = await _showMultiSelectSheet(
      title: 'Brands',
      options: _visibleBrandOptions,
      selected: _selectedBrands,
    );
    if (result != null) {
      await _updateSelection(brands: result);
    }
  }

  Future<Set<String>?> _showMultiSelectSheet({
    required String title,
    required List<String> options,
    required Set<String> selected,
  }) {
    Set<String> working = Set<String>.of(selected);
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final allSelected = working.isEmpty;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(title, style: Theme.of(sheetContext).textTheme.titleMedium),
                    ),
                    CheckboxListTile(
                      title: const Text('All'),
                      value: allSelected,
                      onChanged: (_) => setSheetState(() => working = <String>{}),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: options.map((option) {
                          final checked = working.contains(option);
                          return CheckboxListTile(
                            title: Text(option),
                            value: checked,
                            onChanged: (value) => setSheetState(() {
                              if (value == true) {
                                working.add(option);
                              } else {
                                working.remove(option);
                                if (working.isEmpty) working = <String>{};
                              }
                            }),
                          );
                        }).toList(growable: false),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton(
                          onPressed: () => Navigator.of(sheetContext).pop(working),
                          child: const Text('Done'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _summaryFor(Set<String> selected) {
    if (selected.isEmpty) return 'All';
    if (selected.length == 1) return selected.first;
    return '${selected.length} selected';
  }

  bool get _hasReadyTransmitter {
    final caps = _capabilities;
    if (caps == null) return true; // don't block on a failed capability check
    return caps.hasInternal || caps.hasUsb;
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
    switch (_state) {
      case _LoadState.loading:
        return const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Getting ready…'),
            ],
          ),
        );
      case _LoadState.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_off_rounded,
                    size: 48, color: Theme.of(context).colorScheme.error),
                const SizedBox(height: 12),
                const Text(
                  "Couldn't load the device database",
                  style: TextStyle(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => unawaited(_bootstrap()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        );
      case _LoadState.ready:
        return _buildReadyBody(context);
    }
  }

  Widget _buildReadyBody(BuildContext context) {
    final filtered = _filteredFiles;
    final powerSignals = matchingPowerSignals(filtered);
    final muteSignals = matchingMuteSignals(filtered);
    final loadingSelection = _loadingTypes.isNotEmpty;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (!_hasReadyTransmitter) _buildNoTransmitterBanner(context),
        _FilterField(
          label: 'Device type',
          value: _summaryFor(_selectedDeviceTypes),
          onTap: _pickDeviceTypes,
        ),
        const SizedBox(height: 10),
        _FilterField(
          label: 'Brands',
          value: _summaryFor(_selectedBrands),
          onTap: _pickBrands,
        ),
        const SizedBox(height: 28),
        if (loadingSelection)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (filtered.isEmpty || (powerSignals.isEmpty && muteSignals.isEmpty))
          const _EmptyMatchMessage()
        else
          AnimatedBuilder(
            animation: RemoteDisplayController.instance,
            builder: (context, _) => _ActionArea(
              powerSignals: powerSignals,
              muteSignals: muteSignals,
              powerController: _powerController,
              muteController: _muteController,
              showSignalCounts: RemoteDisplayController.instance.showButtonMetadata,
            ),
          ),
      ],
    );
  }

  Widget _buildNoTransmitterBanner(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.usb_off_rounded, color: Theme.of(context).colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Plug in your IR dongle to use Everything-B-Gone.',
                style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _FilterField({required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: cs.outlineVariant),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant)),
                  Text(value, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _EmptyMatchMessage extends StatelessWidget {
  const _EmptyMatchMessage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.filter_alt_off_rounded,
              size: 40, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            'No matches for this combination — try selecting more brands or a different device type.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  final List<FlipperIrSignal> powerSignals;
  final List<FlipperIrSignal> muteSignals;
  final TransmitCycleController<FlipperIrSignal> powerController;
  final TransmitCycleController<FlipperIrSignal> muteController;
  final bool showSignalCounts;

  const _ActionArea({
    required this.powerSignals,
    required this.muteSignals,
    required this.powerController,
    required this.muteController,
    required this.showSignalCounts,
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

  const _CycleControl({
    required this.label,
    required this.signals,
    required this.controller,
    required this.otherRunning,
    required this.color,
    required this.onColor,
    required this.big,
    required this.showSignalCount,
  });

  @override
  Widget build(BuildContext context) {
    final running = controller.running;

    if (running) {
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
          SizedBox(
            width: 220,
            child: LinearProgressIndicator(
              value: controller.total == 0 ? null : controller.attempted / controller.total,
            ),
          ),
        ],
      );
    }

    final onPressed =
        otherRunning ? null : () => controller.start(signals, delayMs: 700);

    if (big) {
      return SizedBox(
        width: 160,
        height: 160,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            shape: const CircleBorder(),
            backgroundColor: color,
            foregroundColor: onColor,
          ),
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
