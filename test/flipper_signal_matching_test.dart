import 'package:flutter_test/flutter_test.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';
import 'package:everythingbgone/flipper_irdb/signal_matching.dart';

FlipperIrFile _fileWithSignalNames(List<String> names) {
  return FlipperIrFile(
    deviceType: 'TVs',
    brand: 'Samsung',
    fileName: 'test.ir',
    path: 'TVs/Samsung/test.ir',
    signals: names.map((n) => FlipperIrSignal(name: n)).toList(),
  );
}

void main() {
  group('powerOrOffSignalFor', () {
    test('picks the power-named signal when only "power" exists', () {
      final file = _fileWithSignalNames(['Vol_up', 'Power', 'Mute']);
      expect(powerOrOffSignalFor(file)?.name, 'Power');
    });

    test('falls back to "off" only when no "power" signal exists', () {
      final file = _fileWithSignalNames(['Vol_up', 'Off', 'Mute']);
      expect(powerOrOffSignalFor(file)?.name, 'Off');
    });

    test('prefers "power" over "off" when both are present', () {
      final file = _fileWithSignalNames(['Off', 'Power_toggle']);
      expect(powerOrOffSignalFor(file)?.name, 'Power_toggle');
    });

    test('returns null when neither "power" nor "off" is present', () {
      final file = _fileWithSignalNames(['Vol_up', 'Vol_down', 'Mute']);
      expect(powerOrOffSignalFor(file), isNull);
    });

    test('matching is case-insensitive', () {
      final file = _fileWithSignalNames(['POWER_ON']);
      expect(powerOrOffSignalFor(file)?.name, 'POWER_ON');
    });

    test('matches "power" as a substring, not just a whole word', () {
      final file = _fileWithSignalNames(['ToggleFullPowerState']);
      expect(powerOrOffSignalFor(file)?.name, 'ToggleFullPowerState');
    });
  });

  group('muteSignalFor', () {
    test('finds a mute-named signal', () {
      final file = _fileWithSignalNames(['Power', 'Mute', 'Vol_up']);
      expect(muteSignalFor(file)?.name, 'Mute');
    });

    test('returns null when there is no mute signal', () {
      final file = _fileWithSignalNames(['Power', 'Vol_up', 'Vol_down']);
      expect(muteSignalFor(file), isNull);
    });

    test('mute matching is case-insensitive', () {
      final file = _fileWithSignalNames(['MUTE']);
      expect(muteSignalFor(file)?.name, 'MUTE');
    });
  });
}
