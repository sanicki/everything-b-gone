import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:everythingbgone/utils/ir_transmitter_platform.dart';

import 'filter_logic.dart';
import 'flipper_irdb_models.dart';
import 'flipper_irdb_service.dart';
import 'kill_switch_prefs.dart';

enum KillSwitchLoadState { loading, error, ready }

/// Owns the Flipper-IRDB tree/qualification/per-type file cache, the
/// current Device Type / Brand filter selection, and the live transmitter
/// capabilities — shared by every screen that needs to browse or fire
/// matching signals (the Everything-B-Gone home screen and the List screen)
/// so they see one consistent, already-loaded picture instead of each
/// fetching and scanning independently.
class KillSwitchDataController extends ChangeNotifier {
  KillSwitchDataController._();
  static final KillSwitchDataController instance = KillSwitchDataController._();

  final FlipperIrdbService _service = FlipperIrdbService();

  KillSwitchLoadState state = KillSwitchLoadState.loading;
  String errorMessage = '';

  FlipperIrdbTree? tree;
  FlipperQualification? qualification;
  final Map<String, List<FlipperIrFile>> loadedFiles = <String, List<FlipperIrFile>>{};
  final Set<String> loadingTypes = <String>{};

  Set<String> selectedDeviceTypes = <String>{'TVs'};
  Set<String> selectedBrands = <String>{};

  IrTransmitterCapabilities? capabilities;
  StreamSubscription<IrTransmitterCapabilities>? _capsSub;

  Future<void>? _bootstrapFuture;

  /// Kicks off the initial load exactly once, no matter how many screens
  /// call this during their `initState`; later callers just await the same
  /// in-flight (or already-completed) future.
  Future<void> ensureBootstrapped() {
    return _bootstrapFuture ??= _bootstrap();
  }

  /// Re-runs the initial load after a failure — used by each screen's
  /// Retry button.
  Future<void> retry() {
    _bootstrapFuture = _bootstrap();
    return _bootstrapFuture!;
  }

  Future<void> _bootstrap() async {
    state = KillSwitchLoadState.loading;
    notifyListeners();

    _capsSub ??= IrTransmitterPlatform.capabilitiesEvents().listen(
      (caps) {
        capabilities = caps;
        notifyListeners();
      },
      onError: (_) {},
      cancelOnError: false,
    );

    try {
      capabilities = await IrTransmitterPlatform.getCapabilities();
    } catch (_) {
      capabilities = null;
    }

    final savedTypes = await KillSwitchFilterPrefs.loadDeviceTypes();
    final savedBrands = await KillSwitchFilterPrefs.loadBrands();
    if (savedTypes.isNotEmpty) selectedDeviceTypes = savedTypes;
    selectedBrands = savedBrands;

    qualification = await _service.loadQualification();

    try {
      tree = await _service.fetchTree();
    } catch (e) {
      state = KillSwitchLoadState.error;
      errorMessage = e.toString();
      notifyListeners();
      return;
    }

    await ensureFilesLoadedForSelection();
    state = KillSwitchLoadState.ready;
    notifyListeners();

    unawaited(_runQualificationScanInBackground());
  }

  Future<void> ensureFilesLoadedForSelection() async {
    final currentTree = tree;
    if (currentTree == null) return;
    final types =
        selectedDeviceTypes.isEmpty ? currentTree.deviceTypes : selectedDeviceTypes.toList();
    for (final type in types) {
      if (loadedFiles.containsKey(type) || loadingTypes.contains(type)) continue;
      loadingTypes.add(type);
      notifyListeners();
      try {
        loadedFiles[type] = await _service.fetchDeviceTypeFiles(type, currentTree);
      } catch (_) {
        loadedFiles[type] = const <FlipperIrFile>[];
      } finally {
        loadingTypes.remove(type);
      }
    }
    notifyListeners();
  }

  Future<void> _runQualificationScanInBackground() async {
    final currentTree = tree;
    if (currentTree == null) return;
    try {
      final firstType =
          selectedDeviceTypes.isNotEmpty ? selectedDeviceTypes.first : null;
      final result = await _service.runQualificationScan(
        currentTree,
        skip: firstType,
        skipFiles: firstType != null ? loadedFiles[firstType] : null,
      );
      qualification = result;
      notifyListeners();
    } catch (_) {
      // Best-effort: filters just stay unfiltered by qualification if this fails.
    }
  }

  Future<void> updateSelection({Set<String>? deviceTypes, Set<String>? brands}) async {
    if (deviceTypes != null) selectedDeviceTypes = deviceTypes;
    if (brands != null) selectedBrands = brands;
    notifyListeners();
    await KillSwitchFilterPrefs.save(
      deviceTypes: selectedDeviceTypes,
      brands: selectedBrands,
    );
    await ensureFilesLoadedForSelection();
  }

  List<FlipperIrFile> get allLoadedFiles {
    final all = <FlipperIrFile>[];
    for (final files in loadedFiles.values) {
      all.addAll(files);
    }
    return all;
  }

  List<FlipperIrFile> get filteredFiles => filterFiles(
        allLoadedFiles,
        FilterSelection(deviceTypes: selectedDeviceTypes, brands: selectedBrands),
      );

  List<String> get visibleDeviceTypeOptions {
    final currentTree = tree;
    if (currentTree == null) return const <String>[];
    final currentQualification = qualification;
    if (currentQualification == null) return currentTree.deviceTypes;
    return visibleDeviceTypes(currentTree, currentQualification);
  }

  List<String> get visibleBrandOptions {
    final currentTree = tree;
    if (currentTree == null) return const <String>[];
    final types =
        selectedDeviceTypes.isEmpty ? currentTree.deviceTypes : selectedDeviceTypes.toList();
    final currentQualification = qualification;
    final set = <String>{};
    for (final type in types) {
      set.addAll(
        currentQualification == null
            ? currentTree.brandsFor(type)
            : visibleBrands(currentTree, currentQualification, type),
      );
    }
    final list = set.toList()..sort();
    return list;
  }

  bool get loadingSelection => loadingTypes.isNotEmpty;

  bool get hasReadyTransmitter {
    final caps = capabilities;
    if (caps == null) return true; // don't block on a failed capability check
    return caps.hasInternal || caps.hasUsb;
  }
}
