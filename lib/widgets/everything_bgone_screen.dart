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
import 'package:everythingbgone/state/transmit_cycle_prefs.dart';
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
    final powerMatches = matchingPowerBrandSignals(filtered);
    final muteMatches = matchingMuteBrandSignals(filtered);
    final powerSignals = powerMatches.map((m) => m.signal).toList(growable: false);
    final muteSignals = muteMatches.map((m) => m.signal).toList(growable: false);
    final powerBrands = powerMatches.map((m) => m.brand).toList(growable: false);
    final muteBrands = muteMatches.map((m) => m.brand).toList(growable: false);
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
              powerBrands: powerBrands,
              muteBrands: muteBrands,
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
  final List<String> powerBrands;
  final List<String> muteBrands;
  final TransmitCycleController<FlipperIrSignal> powerController;
  final TransmitCycleController<FlipperIrSignal> muteController;
  final bool showSignalCounts;

  const _ActionArea({
    required this.powerSignals,
    required this.muteSignals,
    required this.powerBrands,
    required this.muteBrands,
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
            brands: powerBrands,
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
            brands: muteBrands,
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
  final List<String> brands;
  final TransmitCycleController<FlipperIrSignal> controller;
  final bool otherRunning;
  final Color color;
  final Color onColor;
  final bool big;
  final bool showSignalCount;

  const _CycleControl({
    required this.label,
    required this.signals,
    required this.brands,
    required this.controller,
    required this.otherRunning,
    required this.color,
    required this.onColor,
    required this.big,
    required this.showSignalCount,
  });

  Widget _circle({
    required VoidCallback? onPressed,
    required Color background,
    required Color foreground,
    required Widget child,
  }) {
    return SizedBox(
      width: 160,
      height: 160,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: background,
          foregroundColor: foreground,
        ),
        child: child,
      ),
    );
  }

  /// The index a "skip this brand" tap would jump to: past every remaining
  /// candidate that shares a brand with the one just sent (or, if nothing
  /// has sent yet, the one about to send). Also tells the caller whether
  /// skipping would just end the run (nothing left after this brand).
  int _skipTargetIndex() {
    if (brands.isEmpty) return 0;
    final attempted = controller.attempted;
    final refIndex =
        attempted > 0 ? attempted - 1 : (attempted < brands.length ? attempted : -1);
    if (refIndex < 0 || refIndex >= brands.length) return brands.length;
    final referenceBrand = brands[refIndex];
    var target = attempted;
    while (target < brands.length && brands[target] == referenceBrand) {
      target++;
    }
    return target;
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

      // Match the color FilledButton.tonalIcon used for the pill this
      // circle replaces while running, instead of the idle primary color.
      final cs = Theme.of(context).colorScheme;
      final skipTarget = _skipTargetIndex();
      final skipEndsRun = skipTarget >= controller.total;
      final countText =
          showSignalCount ? '${controller.attempted}/${controller.total}' : null;

      return Column(
        children: [
          _HoldToSkipOrStop(
            big: big,
            background: cs.secondaryContainer,
            foreground: cs.onSecondaryContainer,
            skipEndsRun: skipEndsRun,
            countText: countText,
            onSkipBrand: () => controller.skipTo(skipTarget),
            onStop: controller.stop,
          ),
          const SizedBox(height: 8),
          progressBar,
        ],
      );
    }

    final onPressed = otherRunning
        ? null
        : () => controller.start(signals, delayMs: TransmitCyclePrefs.instance.delayMs);

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

/// The control shown while a Power/Mute cycle is running. A quick tap
/// skips the remaining signals for the brand that just fired (or is about
/// to); holding past a short threshold stops the whole run instead. The
/// button progressively morphs from the skip face to the stop face as the
/// hold approaches that threshold — via a clock-style radial sweep on the
/// Power circle / a left-to-right sweep on the Mute pill, both tied to
/// actual hold duration — so the two very different actions never share a
/// single ambiguous instant. When skipping the current brand would just
/// end the run anyway (it's the last brand left), there's nothing left to
/// distinguish "skip" from "stop": the control shows the stop face at
/// rest and a plain tap stops immediately, same as before this feature.
class _HoldToSkipOrStop extends StatefulWidget {
  final bool big;
  final Color background;
  final Color foreground;
  final bool skipEndsRun;
  final String? countText;
  final VoidCallback onSkipBrand;
  final VoidCallback onStop;

  const _HoldToSkipOrStop({
    required this.big,
    required this.background,
    required this.foreground,
    required this.skipEndsRun,
    required this.countText,
    required this.onSkipBrand,
    required this.onStop,
  });

  @override
  State<_HoldToSkipOrStop> createState() => _HoldToSkipOrStopState();
}

class _HoldToSkipOrStopState extends State<_HoldToSkipOrStop>
    with SingleTickerProviderStateMixin {
  static const _holdThreshold = Duration(milliseconds: 550);

  late final AnimationController _hold = AnimationController(
    vsync: this,
    duration: _holdThreshold,
  )..addStatusListener(_onHoldStatusChanged);

  bool _pressed = false;

  void _onHoldStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      widget.onStop();
    }
  }

  void _onTapDown(TapDownDetails _) {
    _pressed = true;
    _hold.forward(from: 0);
  }

  void _onTapUp(TapUpDetails _) {
    if (!_pressed) return;
    _pressed = false;
    if (_hold.status == AnimationStatus.completed) return;
    _hold.reverse();
    widget.onSkipBrand();
  }

  void _onTapCancel() {
    _pressed = false;
    if (_hold.status != AnimationStatus.completed) {
      _hold.reverse();
    }
  }

  @override
  void dispose() {
    _hold.dispose();
    super.dispose();
  }

  Widget _face({required IconData icon, required String label}) {
    if (widget.big) {
      final children = <Widget>[
        Icon(icon, size: 40, color: widget.foreground),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: widget.foreground)),
      ];
      if (widget.countText != null) {
        children.add(Text(widget.countText!,
            style: TextStyle(fontSize: 11, color: widget.foreground)));
      }
      return Column(mainAxisSize: MainAxisSize.min, children: children);
    }

    final children = <Widget>[
      Icon(icon, size: 20, color: widget.foreground),
      const SizedBox(width: 8),
      Text(label,
          style: TextStyle(fontWeight: FontWeight.w600, color: widget.foreground)),
    ];
    if (widget.countText != null) {
      children.add(const SizedBox(width: 6));
      children.add(Text('(${widget.countText})', style: TextStyle(color: widget.foreground)));
    }
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.skipEndsRun) {
      final content = _face(icon: Icons.stop_rounded, label: 'Stop');
      if (widget.big) {
        return SizedBox(
          width: 160,
          height: 160,
          child: FilledButton(
            onPressed: widget.onStop,
            style: FilledButton.styleFrom(
              shape: const CircleBorder(),
              backgroundColor: widget.background,
              foregroundColor: widget.foreground,
            ),
            child: content,
          ),
        );
      }
      return SizedBox(
        width: 220,
        height: 48,
        child: FilledButton.tonal(
          onPressed: widget.onStop,
          style: FilledButton.styleFrom(
            backgroundColor: widget.background,
            foregroundColor: widget.foreground,
          ),
          child: content,
        ),
      );
    }

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _hold,
        builder: (context, _) {
          final progress = _hold.value;
          final skipOpacity = (1 - progress * 2).clamp(0.0, 1.0);
          final stopOpacity = ((progress - 0.5) * 2).clamp(0.0, 1.0);
          final crossfaded = Stack(
            alignment: Alignment.center,
            children: [
              Opacity(
                opacity: skipOpacity,
                child: _face(icon: Icons.fast_forward_rounded, label: 'Next Brand'),
              ),
              Opacity(
                opacity: stopOpacity,
                child: _face(icon: Icons.stop_rounded, label: 'Stop'),
              ),
            ],
          );

          if (widget.big) {
            return SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Material(
                      color: widget.background,
                      shape: const CircleBorder(),
                      child: Center(child: crossfaded),
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 4,
                          backgroundColor: Colors.transparent,
                          color: widget.foreground.withValues(
                              alpha: (progress * 0.9).clamp(0.0, 0.9)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return SizedBox(
            width: 220,
            height: 48,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: Material(
                color: widget.background,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(color: widget.foreground.withValues(alpha: 0.20)),
                      ),
                    ),
                    Center(child: crossfaded),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
