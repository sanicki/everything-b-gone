import 'package:uuid/uuid.dart';

/// A single IR signal: either a legacy raw/hex `code`+`rawData` pair, or a
/// `protocol`+`protocolParams` pair matching `IrProtocolRegistry`. Kept as
/// shared infra for `previewIRButton` (lib/utils/ir.dart) and its NEC
/// bit-order regression tests — the `Remote` container and its
/// `remotes.json` persistence this used to live alongside were removed
/// with the Remotes feature.
class IRButton {
  final String id;
  final int? code;
  final String? rawData;
  final int? frequency;
  final String image;
  final bool isImage;
  final String? necBitOrder;
  final String? protocol;
  final Map<String, dynamic>? protocolParams;
  final int? iconCodePoint;
  final String? iconFontFamily;
  final String? iconFontPackage;
  final int? iconColor;
  final int? buttonColor;

  const IRButton({
    required this.id,
    this.code,
    this.rawData,
    this.frequency,
    required this.image,
    required this.isImage,
    this.necBitOrder,
    this.protocol,
    this.protocolParams,
    this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.iconColor,
    this.buttonColor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'code': code,
        'rawData': rawData,
        'frequency': frequency,
        'image': image,
        'isImage': isImage,
        'necBitOrder': necBitOrder,
        'protocol': protocol,
        'protocolParams': protocolParams,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'iconFontPackage': iconFontPackage,
        'iconColor': iconColor,
        'buttonColor': buttonColor,
      };

  factory IRButton.fromJson(Map<String, dynamic> json) {
    final pp = json['protocolParams'];
    final rawId = (json['id'] as String?)?.trim();
    return IRButton(
      id: (rawId == null || rawId.isEmpty) ? const Uuid().v4() : rawId,
      code: json['code'] is int ? json['code'] as int? : int.tryParse('${json['code']}'),
      rawData: json['rawData'] as String?,
      frequency: json['frequency'] is int ? json['frequency'] as int? : int.tryParse('${json['frequency']}'),
      image: (json['image'] as String?) ?? '',
      isImage: (json['isImage'] as bool?) ?? true,
      necBitOrder: json['necBitOrder'] as String?,
      protocol: json['protocol'] as String?,
      protocolParams: (pp is Map) ? Map<String, dynamic>.from(pp) : null,
      iconCodePoint: json['iconCodePoint'] is int ? json['iconCodePoint'] as int? : int.tryParse('${json['iconCodePoint'] ?? ''}'),
      iconFontFamily: json['iconFontFamily'] as String?,
      iconFontPackage: _resolveIconFontPackage(
        json['iconFontPackage'] as String?,
        json['iconFontFamily'] as String?,
      ),
      iconColor: json['iconColor'] is int ? json['iconColor'] as int? : int.tryParse('${json['iconColor'] ?? ''}'),
      buttonColor: json['buttonColor'] is int ? json['buttonColor'] as int? : int.tryParse('${json['buttonColor'] ?? ''}'),
    );
  }

  IRButton copyWith({
    String? id,
    int? code,
    String? rawData,
    int? frequency,
    String? image,
    bool? isImage,
    String? necBitOrder,
    String? protocol,
    Map<String, dynamic>? protocolParams,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    int? iconColor,
    int? buttonColor,
  }) {
    return IRButton(
      id: id ?? this.id,
      code: code ?? this.code,
      rawData: rawData ?? this.rawData,
      frequency: frequency ?? this.frequency,
      image: image ?? this.image,
      isImage: isImage ?? this.isImage,
      necBitOrder: necBitOrder ?? this.necBitOrder,
      protocol: protocol ?? this.protocol,
      protocolParams: protocolParams ?? this.protocolParams,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      iconColor: iconColor ?? this.iconColor,
      buttonColor: buttonColor ?? this.buttonColor,
    );
  }
}

String? _resolveIconFontPackage(String? explicitPackage, String? fontFamily) {
  final pkg = explicitPackage?.trim();
  if (pkg != null && pkg.isNotEmpty) return pkg;

  final family = fontFamily?.trim();
  if (family == null || family.isEmpty) return null;
  if (family.toLowerCase().contains('fontawesome')) {
    return 'font_awesome_flutter';
  }
  return null;
}
