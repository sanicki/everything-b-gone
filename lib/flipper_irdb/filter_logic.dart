import 'flipper_irdb_models.dart';
import 'signal_matching.dart';

/// The user's current Device Type / Brand picks. An empty set means "All"
/// for that dimension (checking "All" clears individual picks and vice
/// versa — that toggling lives in the screen; this class just represents
/// the resulting selection).
class FilterSelection {
  final Set<String> deviceTypes;
  final Set<String> brands;

  const FilterSelection({
    this.deviceTypes = const <String>{},
    this.brands = const <String>{},
  });

  bool get allDeviceTypes => deviceTypes.isEmpty;
  bool get allBrands => brands.isEmpty;
}

/// Device types to show as filter options: every device type in the tree,
/// except one *confirmed* (already scanned) to have zero qualifying
/// brands. A type that hasn't been scanned yet is shown — hiding it would
/// be indistinguishable from "we checked and it has nothing", which isn't
/// true yet.
List<String> visibleDeviceTypes(
  FlipperIrdbTree tree,
  FlipperQualification qualification,
) {
  return tree.deviceTypes.where((type) {
    if (!qualification.isDeviceTypeScanned(type)) return true;
    return qualification.qualifyingBrandsFor(type).isNotEmpty;
  }).toList();
}

/// Brands to show for [deviceType]: every brand under it in the tree,
/// except one confirmed to have zero qualifying signals for that specific
/// device type. Same not-yet-scanned-means-show rule as device types.
List<String> visibleBrands(
  FlipperIrdbTree tree,
  FlipperQualification qualification,
  String deviceType,
) {
  final allBrands = tree.brandsFor(deviceType);
  if (!qualification.isDeviceTypeScanned(deviceType)) return allBrands;
  final qualifying = qualification.qualifyingBrandsFor(deviceType);
  return allBrands.where(qualifying.contains).toList();
}

/// Narrows [files] (already-loaded `.ir` files for whichever device types
/// are relevant) down to the ones matching the current filter selection.
/// "All" on either axis contributes no constraint on that axis, so
/// selecting individual device types AND individual brands intersects both
/// — which can legitimately narrow to zero files.
List<FlipperIrFile> filterFiles(
  List<FlipperIrFile> files,
  FilterSelection selection,
) {
  return files.where((file) {
    final typeOk =
        selection.allDeviceTypes || selection.deviceTypes.contains(file.deviceType);
    final brandOk =
        selection.allBrands || selection.brands.contains(file.brand);
    return typeOk && brandOk;
  }).toList();
}

/// The Power button's candidate signals across the filtered file set: one
/// per file at most (a file's own power-then-off preference, via
/// [powerOrOffSignalFor]), skipping files with neither, then deduplicated
/// so identical transmissions (common across models sharing a protocol)
/// are only sent once per cycle.
List<FlipperIrSignal> matchingPowerSignals(List<FlipperIrFile> filteredFiles) {
  return _dedupeSignals(
    filteredFiles.map(powerOrOffSignalFor).whereType<FlipperIrSignal>(),
  );
}

/// The Mute button's candidate signals across the filtered file set,
/// deduplicated the same way as [matchingPowerSignals].
List<FlipperIrSignal> matchingMuteSignals(List<FlipperIrFile> filteredFiles) {
  return _dedupeSignals(
    filteredFiles.map(muteSignalFor).whereType<FlipperIrSignal>(),
  );
}

List<FlipperIrSignal> _dedupeSignals(Iterable<FlipperIrSignal> signals) {
  final seenKeys = <String>{};
  final result = <FlipperIrSignal>[];
  for (final signal in signals) {
    if (seenKeys.add(signal.dedupeKey)) {
      result.add(signal);
    }
  }
  return result;
}

/// One row on the manual signal-testing (List) screen: a single file's
/// Brand, an "Option N" disambiguator when multiple files share that Brand
/// within the same Device Type, and its power/mute test signals (either may
/// be null if the file lacks that kind of signal).
class SignalListRow {
  final FlipperIrFile file;
  final String? optionLabel;
  final FlipperIrSignal? powerSignal;
  final FlipperIrSignal? muteSignal;

  const SignalListRow({
    required this.file,
    required this.optionLabel,
    required this.powerSignal,
    required this.muteSignal,
  });

  String get brand => file.brand;
}

/// One Device Type section for the List screen: its rows, grouped by Brand.
class SignalListGroup {
  final String deviceType;
  final List<SignalListRow> rows;

  const SignalListGroup({required this.deviceType, required this.rows});
}

/// Builds the List screen's Device Type -> Brand row groups from an
/// already-filtered file set, skipping any file with neither a power/off nor
/// a mute signal (nothing to test), then de-duping rows that share a Device
/// Type, Brand, Power signal, and Mute signal (compared by what they
/// actually transmit, via `dedupeKey` — not by file name), keeping the
/// first survivor in file-name order. Remaining same-brand rows are then
/// numbered "Option N" by that same order; a brand left with only one row
/// gets no option label at all. Device types and brands are both sorted
/// alphabetically for a stable, predictable order.
List<SignalListGroup> buildSignalListGroups(List<FlipperIrFile> filteredFiles) {
  final byType = <String, List<FlipperIrFile>>{};
  for (final file in filteredFiles) {
    byType.putIfAbsent(file.deviceType, () => <FlipperIrFile>[]).add(file);
  }

  final groups = <SignalListGroup>[];
  for (final deviceType in byType.keys.toList()..sort()) {
    final byBrand = <String, List<FlipperIrFile>>{};
    for (final file in byType[deviceType]!) {
      byBrand.putIfAbsent(file.brand, () => <FlipperIrFile>[]).add(file);
    }

    final rows = <SignalListRow>[];
    for (final brand in byBrand.keys.toList()..sort()) {
      final files = byBrand[brand]!..sort((a, b) => a.fileName.compareTo(b.fileName));

      final seenKeys = <(String?, String?)>{};
      final survivors = <SignalListRow>[];
      for (final file in files) {
        final power = powerOrOffSignalFor(file);
        final mute = muteSignalFor(file);
        if (power == null && mute == null) continue;
        final key = (power?.dedupeKey, mute?.dedupeKey);
        if (!seenKeys.add(key)) continue;
        survivors.add(SignalListRow(
          file: file,
          optionLabel: null, // filled in below once we know the final count
          powerSignal: power,
          muteSignal: mute,
        ));
      }

      final multiple = survivors.length > 1;
      for (var i = 0; i < survivors.length; i++) {
        final row = survivors[i];
        rows.add(multiple
            ? SignalListRow(
                file: row.file,
                optionLabel: 'Option ${i + 1}',
                powerSignal: row.powerSignal,
                muteSignal: row.muteSignal,
              )
            : row);
      }
    }

    if (rows.isNotEmpty) {
      groups.add(SignalListGroup(deviceType: deviceType, rows: rows));
    }
  }
  return groups;
}
