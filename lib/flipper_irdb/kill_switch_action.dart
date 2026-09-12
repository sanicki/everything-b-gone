import 'package:everythingbgone/flipper_irdb/filter_logic.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_service.dart';
import 'package:everythingbgone/flipper_irdb/kill_switch_prefs.dart';
import 'package:everythingbgone/ir/ir_protocol_registry.dart';
import 'package:everythingbgone/utils/ir.dart';

enum KillSwitchAction { power, mute }

/// Loads the cached Flipper-IRDB data for the user's saved filter
/// selection and returns the matching signals for [action] — the same
/// computation the main screen does (see `filterFiles`/`matchingPowerSignals`
/// /`matchingMuteSignals` in `filter_logic.dart`), factored out here so
/// headless triggers (quick settings tiles, Device Controls, the home
/// widget) can fire it without the UI open. Relies entirely on whatever is
/// already cached — a headless trigger never blocks on a network fetch.
Future<List<FlipperIrSignal>> loadMatchingSignals(KillSwitchAction action) async {
  final service = FlipperIrdbService();
  final tree = await service.fetchTree();
  final deviceTypes = await KillSwitchFilterPrefs.loadDeviceTypes();
  final brands = await KillSwitchFilterPrefs.loadBrands();
  final selection = FilterSelection(deviceTypes: deviceTypes, brands: brands);

  final relevantTypes = deviceTypes.isEmpty ? tree.deviceTypes : deviceTypes.toList();
  final files = <FlipperIrFile>[];
  for (final type in relevantTypes) {
    files.addAll(await service.fetchDeviceTypeFiles(type, tree));
  }

  final filtered = filterFiles(files, selection);
  return action == KillSwitchAction.power
      ? matchingPowerSignals(filtered)
      : matchingMuteSignals(filtered);
}

/// Transmits every signal in [signals] once, back-to-back with a short
/// delay between each, swallowing per-signal errors so one bad file
/// doesn't stop the rest. Used for headless (no progress UI) triggers —
/// the main screen instead drives `TransmitCycleController` for the same
/// list, to get pause/stop/progress.
Future<void> transmitAllHeadless(
  List<FlipperIrSignal> signals, {
  int delayMs = 250,
}) async {
  for (final signal in signals) {
    try {
      await _transmitSignal(signal);
    } catch (_) {
      // keep going — one bad file shouldn't block the rest of the cycle.
    }
    await Future.delayed(Duration(milliseconds: delayMs));
  }
}

Future<void> _transmitSignal(FlipperIrSignal signal) async {
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
  final result = encoder.encode(signal.protocolParams ?? const <String, dynamic>{});
  await transmitRaw(result.frequencyHz, result.pattern);
}

/// Loads and fires [action] end-to-end — the single entry point headless
/// triggers call.
Future<void> fireKillSwitchAction(KillSwitchAction action) async {
  final signals = await loadMatchingSignals(action);
  await transmitAllHeadless(signals);
}
