import 'package:flutter_test/flutter_test.dart';
import 'package:everythingbgone/flipper_irdb/flipper_ir_parser.dart';

const String _rawBlock = '''
Filetype: IR signals file
Version: 1
#
name: Power
type: raw
frequency: 38000
duty_cycle: 0.330000
data: 9042 4484 573 573 573 1693 573 573
#
''';

const String _necBlock = '''
Filetype: IR signals file
Version: 1
#
name: Power
type: parsed
protocol: NEC
address: 00 00 00 00
command: 12 ED 00 00
#
''';

const String _kaseikyoBlock = '''
Filetype: IR signals file
Version: 1
#
name: Mute
type: parsed
protocol: Kaseikyo
address: 02 20 00 00
command: 0D 00 00 00
#
''';

const String _rc5Block = '''
Filetype: IR signals file
Version: 1
#
name: Power
type: parsed
protocol: RC5
address: 00 00 00 00
command: 0C 00 00 00
#
''';

const String _unknownProtocolBlock = '''
Filetype: IR signals file
Version: 1
#
name: Power
type: parsed
protocol: SomeMadeUpProtocol
address: 00 00 00 00
command: 12 00 00 00
#
''';

void main() {
  group('parseFlipperIrFile', () {
    test('parses a raw-timing block', () {
      final signals = parseFlipperIrFile(_rawBlock);
      expect(signals, hasLength(1));
      expect(signals.single.name, 'Power');
      expect(signals.single.isRaw, isTrue);
      expect(signals.single.frequencyHz, 38000);
      expect(signals.single.rawData, contains('9042'));
    });

    test('parses a NEC protocol block into protocol+params', () {
      final signals = parseFlipperIrFile(_necBlock);
      expect(signals, hasLength(1));
      final s = signals.single;
      expect(s.name, 'Power');
      expect(s.protocol, 'nec');
      expect(s.isRaw, isFalse);
      expect(s.protocolParams, isNotNull);
      expect(s.protocolParams!['hex'], isA<String>());
    });

    test('parses a Kaseikyo protocol block (4-byte address/command)', () {
      final signals = parseFlipperIrFile(_kaseikyoBlock);
      expect(signals, hasLength(1));
      final s = signals.single;
      expect(s.protocol, 'kaseikyo');
      expect(s.protocolParams!['address'], '02 20 00 00');
      expect(s.protocolParams!['command'], '0D 00 00 00');
    });

    test('parses an RC5 protocol block', () {
      final signals = parseFlipperIrFile(_rc5Block);
      expect(signals, hasLength(1));
      expect(signals.single.protocol, 'rc5');
      expect(signals.single.protocolParams, isNotNull);
    });

    test('skips a block whose protocol is not recognized', () {
      final signals = parseFlipperIrFile(_unknownProtocolBlock);
      expect(signals, isEmpty);
    });

    test('parses multiple signals from one file', () {
      final combined = '$_rawBlock\n$_necBlock\n$_rc5Block';
      final signals = parseFlipperIrFile(combined);
      expect(signals.map((s) => s.name), <String>['Power', 'Power', 'Power']);
    });

    test('returns an empty list for content with no signal blocks', () {
      expect(parseFlipperIrFile('Filetype: IR signals file\nVersion: 1\n'),
          isEmpty);
    });
  });
}
