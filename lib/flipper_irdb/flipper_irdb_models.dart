/// A single named IR signal parsed out of a Flipper Zero `.ir` file — either
/// protocol-encoded (protocol + params, matching `IrProtocolRegistry`'s
/// param shape) or a raw timing pattern, never both.
class FlipperIrSignal {
  final String name;
  final String? protocol;
  final Map<String, dynamic>? protocolParams;
  final String? rawData;
  final int? frequencyHz;

  const FlipperIrSignal({
    required this.name,
    this.protocol,
    this.protocolParams,
    this.rawData,
    this.frequencyHz,
  });

  bool get isRaw => protocol == null;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name,
        if (protocol != null) 'protocol': protocol,
        if (protocolParams != null) 'protocolParams': protocolParams,
        if (rawData != null) 'rawData': rawData,
        if (frequencyHz != null) 'frequencyHz': frequencyHz,
      };

  factory FlipperIrSignal.fromJson(Map<String, dynamic> json) =>
      FlipperIrSignal(
        name: (json['name'] ?? '').toString(),
        protocol: json['protocol'] as String?,
        protocolParams: (json['protocolParams'] as Map?)?.cast<String, dynamic>(),
        rawData: json['rawData'] as String?,
        frequencyHz: json['frequencyHz'] as int?,
      );
}

/// One `.ir` file from the Flipper-IRDB repo, identified by its Device Type
/// and Brand folder, with every signal it contains already parsed.
class FlipperIrFile {
  final String deviceType;
  final String brand;
  final String fileName;
  final String path;
  final List<FlipperIrSignal> signals;

  const FlipperIrFile({
    required this.deviceType,
    required this.brand,
    required this.fileName,
    required this.path,
    required this.signals,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
        'deviceType': deviceType,
        'brand': brand,
        'fileName': fileName,
        'path': path,
        'signals': signals.map((s) => s.toJson()).toList(growable: false),
      };

  factory FlipperIrFile.fromJson(Map<String, dynamic> json) => FlipperIrFile(
        deviceType: (json['deviceType'] ?? '').toString(),
        brand: (json['brand'] ?? '').toString(),
        fileName: (json['fileName'] ?? '').toString(),
        path: (json['path'] ?? '').toString(),
        signals: ((json['signals'] as List?) ?? const [])
            .whereType<Map>()
            .map((m) => FlipperIrSignal.fromJson(m.cast<String, dynamic>()))
            .toList(growable: false),
      );
}

/// The repo's Device Type -> Brand -> file path structure, fetched once and
/// cached until explicitly refreshed.
class FlipperIrdbTree {
  final Map<String, Map<String, List<String>>> deviceTypeToBrandToPaths;
  final DateTime fetchedAt;

  const FlipperIrdbTree({
    required this.deviceTypeToBrandToPaths,
    required this.fetchedAt,
  });

  List<String> get deviceTypes => deviceTypeToBrandToPaths.keys.toList()..sort();

  List<String> brandsFor(String deviceType) =>
      (deviceTypeToBrandToPaths[deviceType]?.keys.toList() ?? <String>[])
        ..sort();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fetchedAt': fetchedAt.millisecondsSinceEpoch,
        'tree': deviceTypeToBrandToPaths.map(
          (type, brands) => MapEntry(type, brands),
        ),
      };

  factory FlipperIrdbTree.fromJson(Map<String, dynamic> json) {
    final rawTree = (json['tree'] as Map?) ?? const {};
    final tree = <String, Map<String, List<String>>>{};
    rawTree.forEach((type, brands) {
      final brandMap = <String, List<String>>{};
      (brands as Map?)?.forEach((brand, paths) {
        brandMap[brand.toString()] =
            ((paths as List?) ?? const []).map((p) => p.toString()).toList();
      });
      tree[type.toString()] = brandMap;
    });
    return FlipperIrdbTree(
      deviceTypeToBrandToPaths: tree,
      fetchedAt: DateTime.fromMillisecondsSinceEpoch(
        json['fetchedAt'] as int? ?? 0,
      ),
    );
  }
}

/// Which Device Types / Brands have at least one qualifying power/mute
/// signal, from the background qualification scan.
///
/// A device type is a *key* in [qualifyingBrandsByDeviceType] once it has
/// been scanned — even if its value is an empty set, meaning "scanned, and
/// confirmed to have zero qualifying brands". A device type that is not a
/// key at all has simply not been scanned yet. This distinction is what
/// lets the UI apply "hide only if *confirmed* empty" rather than hiding
/// everything that hasn't been scanned yet.
class FlipperQualification {
  final Map<String, Set<String>> qualifyingBrandsByDeviceType;
  final DateTime scannedAt;

  const FlipperQualification({
    required this.qualifyingBrandsByDeviceType,
    required this.scannedAt,
  });

  bool isDeviceTypeScanned(String deviceType) =>
      qualifyingBrandsByDeviceType.containsKey(deviceType);

  Set<String> qualifyingBrandsFor(String deviceType) =>
      qualifyingBrandsByDeviceType[deviceType] ?? const <String>{};

  Map<String, dynamic> toJson() => <String, dynamic>{
        'scannedAt': scannedAt.millisecondsSinceEpoch,
        'qualifying': qualifyingBrandsByDeviceType
            .map((type, brands) => MapEntry(type, brands.toList())),
      };

  factory FlipperQualification.fromJson(Map<String, dynamic> json) {
    final raw = (json['qualifying'] as Map?) ?? const {};
    final map = <String, Set<String>>{};
    raw.forEach((type, brands) {
      map[type.toString()] =
          ((brands as List?) ?? const []).map((b) => b.toString()).toSet();
    });
    return FlipperQualification(
      qualifyingBrandsByDeviceType: map,
      scannedAt: DateTime.fromMillisecondsSinceEpoch(
        json['scannedAt'] as int? ?? 0,
      ),
    );
  }
}
