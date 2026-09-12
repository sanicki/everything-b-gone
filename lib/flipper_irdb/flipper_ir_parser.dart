import 'flipper_irdb_models.dart';

/// Parses a Flipper Zero `.ir` file's contents into the signals it defines.
///
/// Ported from the upstream app's `_parseFlipperIrFile` (formerly in
/// `lib/utils/remotes_io.dart`, which also handled JSON backups and
/// IRPlus/LIRC import — none of which apply here), producing the lighter
/// [FlipperIrSignal] shape instead of a full `Remote`/`IRButton`.
List<FlipperIrSignal> parseFlipperIrFile(String content) {
  final List<String> blocks = content.split('#');
  final List<FlipperIrSignal> signals = <FlipperIrSignal>[];

  for (String block in blocks) {
    block = block.trim();
    if (block.isEmpty) continue;

    if (block.contains('type: parsed')) {
      final signal = _parseParsedBlock(block);
      if (signal != null) signals.add(signal);
      continue;
    }

    if (block.contains('type: raw')) {
      final signal = _parseRawBlock(block);
      if (signal != null) signals.add(signal);
      continue;
    }
  }

  return signals;
}

FlipperIrSignal? _parseRawBlock(String block) {
  final nameMatch = RegExp(r'name:\s*(.+)').firstMatch(block);
  final frequencyMatch = RegExp(r'frequency:\s*(\d+)').firstMatch(block);
  final dataMatch = RegExp(r'data:\s*([\d\s]+)').firstMatch(block);
  if (nameMatch == null || frequencyMatch == null || dataMatch == null) {
    return null;
  }
  return FlipperIrSignal(
    name: nameMatch.group(1)!.trim(),
    rawData: dataMatch.group(1)!.trim(),
    frequencyHz: int.parse(frequencyMatch.group(1)!),
  );
}

FlipperIrSignal? _parseParsedBlock(String block) {
  final protoMatch = RegExp(r'protocol:\s*(.+)').firstMatch(block);
  final protocolName = protoMatch?.group(1)?.trim();
  final mappedProtocol = _mapFlipperProtocol(protocolName);

  final nameMatch = RegExp(r'name:\s*(.+)').firstMatch(block);
  if (nameMatch == null) return null;
  final String name = nameMatch.group(1)!.trim();

  final String normalizedProtocol = protocolName?.trim().toLowerCase() ?? '';

  if (normalizedProtocol == 'nec42' || normalizedProtocol == 'nec42ext') {
    final int? address = _readFlipperUint32(block, 'address');
    final int? command = _readFlipperUint32(block, 'command');
    if (address == null || command == null) return null;
    return FlipperIrSignal(
      name: name,
      rawData: _encodeFlipperNec42Raw(
        address: address,
        command: command,
        extended: normalizedProtocol == 'nec42ext',
      ),
      frequencyHz: 38000,
    );
  }

  if (mappedProtocol == 'kaseikyo') {
    final String? fullAddr = RegExp(
      r'address:\s*(([0-9A-Fa-f]{2}\s+){3}[0-9A-Fa-f]{2})',
    ).firstMatch(block)?.group(1);
    final String? fullCmd = RegExp(
      r'command:\s*(([0-9A-Fa-f]{2}\s+){3}[0-9A-Fa-f]{2})',
    ).firstMatch(block)?.group(1);
    if (fullAddr == null || fullCmd == null) return null;

    final addrBytes = fullAddr.trim().split(RegExp(r'\s+'));
    final cmdBytes = fullCmd.trim().split(RegExp(r'\s+'));
    if (addrBytes.length != 4 || cmdBytes.length != 4) return null;

    return FlipperIrSignal(
      name: name,
      protocol: 'kaseikyo',
      frequencyHz: 37000,
      protocolParams: <String, dynamic>{
        'address': addrBytes.map((e) => e.toUpperCase()).join(' '),
        'command': cmdBytes.map((e) => e.toUpperCase()).join(' '),
      },
    );
  }

  final addressMatch =
      RegExp(r'address:\s*([0-9A-Fa-f]{2})\s+([0-9A-Fa-f]{2})')
          .firstMatch(block);
  final commandMatch =
      RegExp(r'command:\s*([0-9A-Fa-f]{2})\s+([0-9A-Fa-f]{2})')
          .firstMatch(block);
  if (addressMatch == null || commandMatch == null) return null;

  switch (mappedProtocol) {
    case 'rc5':
      final int addr = int.parse(addressMatch.group(1)!, radix: 16) & 0x1F;
      final int cmd = int.parse(commandMatch.group(1)!, radix: 16) & 0x7F;
      return FlipperIrSignal(
        name: name,
        protocol: 'rc5',
        frequencyHz: 36000,
        protocolParams: <String, dynamic>{
          'address': addr.toRadixString(16).toUpperCase().padLeft(2, '0'),
          'command': cmd.toRadixString(16).toUpperCase().padLeft(2, '0'),
        },
      );
    case 'rc6':
      final int addr = int.parse(addressMatch.group(1)!, radix: 16) & 0xFF;
      final int cmd = int.parse(commandMatch.group(1)!, radix: 16) & 0xFF;
      final String hex = ((addr << 8) | cmd)
          .toRadixString(16)
          .padLeft(4, '0')
          .toUpperCase();
      return FlipperIrSignal(
        name: name,
        protocol: 'rc6',
        frequencyHz: 36000,
        protocolParams: <String, dynamic>{'hex': hex},
      );
    case 'rca_38':
      final int addrNibble =
          int.parse(addressMatch.group(1)!, radix: 16) & 0x0F;
      final String addrHex = addrNibble.toRadixString(16).toUpperCase();
      final String cmdHex = int.parse(commandMatch.group(1)!, radix: 16)
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
      return FlipperIrSignal(
        name: name,
        protocol: 'rca_38',
        frequencyHz: 38000,
        protocolParams: <String, dynamic>{'address': addrHex, 'command': cmdHex},
      );
    case 'samsung32':
      return FlipperIrSignal(
        name: name,
        protocol: 'samsung32',
        frequencyHz: 38000,
        protocolParams: <String, dynamic>{
          'address': addressMatch.group(1)!.toUpperCase(),
          'command': commandMatch.group(1)!.toUpperCase(),
        },
      );
    case 'pioneer':
      final String addrHex = int.parse(addressMatch.group(1)!, radix: 16)
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
      final String cmdHex = int.parse(commandMatch.group(1)!, radix: 16)
          .toRadixString(16)
          .padLeft(2, '0')
          .toUpperCase();
      return FlipperIrSignal(
        name: name,
        protocol: 'pioneer',
        frequencyHz: 40000,
        protocolParams: <String, dynamic>{'address': addrHex, 'command': cmdHex},
      );
    case 'sony12':
      final int addr = int.parse(addressMatch.group(1)!, radix: 16) & 0x1F;
      final int cmd = int.parse(commandMatch.group(1)!, radix: 16) & 0x7F;
      return FlipperIrSignal(
        name: name,
        protocol: 'sony12',
        frequencyHz: 40000,
        protocolParams: <String, dynamic>{
          'address': addr.toRadixString(16).toUpperCase(),
          'command': cmd.toRadixString(16).padLeft(2, '0').toUpperCase(),
        },
      );
    case 'sony15':
      final int addr = int.parse(addressMatch.group(1)!, radix: 16) & 0xFF;
      final int cmd = int.parse(commandMatch.group(1)!, radix: 16) & 0x7F;
      return FlipperIrSignal(
        name: name,
        protocol: 'sony15',
        frequencyHz: 40000,
        protocolParams: <String, dynamic>{
          'address': addr.toRadixString(16).padLeft(2, '0').toUpperCase(),
          'command': cmd.toRadixString(16).padLeft(2, '0').toUpperCase(),
        },
      );
    case 'sony20':
      final int lo = int.parse(addressMatch.group(1)!, radix: 16) & 0xFF;
      final int hi = int.parse(addressMatch.group(2)!, radix: 16) & 0xFF;
      final int addr = ((hi << 8) | lo) & 0x1FFF;
      final int cmd = int.parse(commandMatch.group(1)!, radix: 16) & 0x7F;
      return FlipperIrSignal(
        name: name,
        protocol: 'sony20',
        frequencyHz: 40000,
        protocolParams: <String, dynamic>{
          'address': addr.toRadixString(16).toUpperCase(),
          'command': cmd.toRadixString(16).padLeft(2, '0').toUpperCase(),
        },
      );
    case 'nec':
    case 'nec2':
    case 'necx1':
      final String hexCode = _convertToLircHex(
        addressMatch,
        commandMatch,
        completeNecInverses: normalizedProtocol == 'nec',
      );
      return FlipperIrSignal(
        name: name,
        protocol: mappedProtocol,
        protocolParams: <String, dynamic>{'hex': hexCode},
      );
    default:
      return null;
  }
}

String? _mapFlipperProtocol(String? name) {
  if (name == null) return null;
  switch (name.trim().toLowerCase()) {
    case 'kaseikyo':
      return 'kaseikyo';
    case 'nec':
      return 'nec';
    case 'necext':
      return 'nec';
    case 'nrc17':
      return 'nrc17';
    case 'pioneer':
      return 'pioneer';
    case 'rc5':
      return 'rc5';
    case 'rc5x':
      return 'rc5';
    case 'rc6':
      return 'rc6';
    case 'rca':
      return 'rca_38';
    case 'samsung32':
      return 'samsung32';
    case 'samsung36':
      return 'samsung36';
    case 'sirc':
      return 'sony12';
    case 'sirc15':
      return 'sony15';
    case 'sirc20':
      return 'sony20';
    case 'xsat':
    case 'x_sat':
    case 'mitsubishi':
      return 'xsat';
    default:
      return null;
  }
}

String _convertToLircHex(
  RegExpMatch addressMatch,
  RegExpMatch commandMatch, {
  required bool completeNecInverses,
}) {
  final int addrByte1 = int.parse(addressMatch.group(1)!, radix: 16);
  final int addrByte2 = int.parse(addressMatch.group(2)!, radix: 16);
  final int cmdByte1 = int.parse(commandMatch.group(1)!, radix: 16);
  final int cmdByte2 = int.parse(commandMatch.group(2)!, radix: 16);

  final int lircCmd = _bitReverse(addrByte1);
  final int lircCmdInv = completeNecInverses && addrByte2 == 0
      ? 0xFF - lircCmd
      : _bitReverse(addrByte2);

  final int lircAddr = _bitReverse(cmdByte1);
  final int lircAddrInv = completeNecInverses && cmdByte2 == 0
      ? 0xFF - lircAddr
      : _bitReverse(cmdByte2);

  return "${lircCmd.toRadixString(16).padLeft(2, '0')}"
          "${lircCmdInv.toRadixString(16).padLeft(2, '0')}"
          "${lircAddr.toRadixString(16).padLeft(2, '0')}"
          "${lircAddrInv.toRadixString(16).padLeft(2, '0')}"
      .toUpperCase();
}

int _bitReverse(int x) {
  return int.parse(
    x.toRadixString(2).padLeft(8, '0').split('').reversed.join(),
    radix: 2,
  );
}

int? _readFlipperUint32(String block, String field) {
  final match = RegExp(
    '$field:\\s*(([0-9A-Fa-f]{2}\\s+){3}[0-9A-Fa-f]{2})',
  ).firstMatch(block);
  if (match == null) return null;

  final bytes = match
      .group(1)!
      .trim()
      .split(RegExp(r'\s+'))
      .map((value) => int.parse(value, radix: 16))
      .toList(growable: false);
  return bytes[0] | (bytes[1] << 8) | (bytes[2] << 16) | (bytes[3] << 24);
}

String _encodeFlipperNec42Raw({
  required int address,
  required int command,
  required bool extended,
}) {
  final int payload = extended
      ? (address & 0x3FFFFFF) | ((command & 0xFFFF) << 26)
      : (address & 0x1FFF) |
          (((~address) & 0x1FFF) << 13) |
          ((command & 0xFF) << 26) |
          (((~command) & 0xFF) << 34);

  final pattern = <int>[9000, 4500];
  for (int i = 0; i < 42; i++) {
    pattern
      ..add(560)
      ..add(((payload >> i) & 1) == 0 ? 560 : 1690);
  }
  pattern.add(560);
  final int used = pattern.fold(0, (sum, duration) => sum + duration);
  pattern.add(110000 - used);
  return pattern.join(' ');
}
