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
/// [powerOrOffSignalFor]), skipping files with neither.
List<FlipperIrSignal> matchingPowerSignals(List<FlipperIrFile> filteredFiles) {
  return filteredFiles
      .map(powerOrOffSignalFor)
      .whereType<FlipperIrSignal>()
      .toList();
}

/// The Mute button's candidate signals across the filtered file set.
List<FlipperIrSignal> matchingMuteSignals(List<FlipperIrFile> filteredFiles) {
  return filteredFiles
      .map(muteSignalFor)
      .whereType<FlipperIrSignal>()
      .toList();
}
