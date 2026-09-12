import 'package:flutter_test/flutter_test.dart';
import 'package:everythingbgone/flipper_irdb/filter_logic.dart';
import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';

FlipperIrdbTree _tree() {
  return FlipperIrdbTree(
    fetchedAt: DateTime.now(),
    deviceTypeToBrandToPaths: {
      'TVs': {
        'Samsung': ['TVs/Samsung/a.ir'],
        'LG': ['TVs/LG/a.ir'],
      },
      'Soundbars': {
        'Sony': ['Soundbars/Sony/a.ir'],
      },
      'Fans': {
        'Generic': ['Fans/Generic/a.ir'],
      },
    },
  );
}

FlipperIrFile _file(String type, String brand) => FlipperIrFile(
      deviceType: type,
      brand: brand,
      fileName: '$brand.ir',
      path: '$type/$brand/$brand.ir',
      signals: const [
        FlipperIrSignal(name: 'Power'),
        FlipperIrSignal(name: 'Mute'),
      ],
    );

void main() {
  group('visibleDeviceTypes / visibleBrands (hide-if-empty)', () {
    test('a device type not yet scanned is shown, not hidden', () {
      final qualification = FlipperQualification(
        scannedAt: DateTime.now(),
        qualifyingBrandsByDeviceType: {
          'TVs': {'Samsung', 'LG'},
          // 'Soundbars' and 'Fans' intentionally absent: not scanned yet.
        },
      );

      final visible = visibleDeviceTypes(_tree(), qualification);
      expect(visible, containsAll(['TVs', 'Soundbars', 'Fans']));
    });

    test('a device type confirmed to have zero qualifying brands is hidden',
        () {
      final qualification = FlipperQualification(
        scannedAt: DateTime.now(),
        qualifyingBrandsByDeviceType: {
          'TVs': {'Samsung', 'LG'},
          'Fans': <String>{}, // scanned: confirmed nothing qualifies
        },
      );

      final visible = visibleDeviceTypes(_tree(), qualification);
      expect(visible, contains('TVs'));
      expect(visible, isNot(contains('Fans')));
      expect(visible, contains('Soundbars'),
          reason: 'not yet scanned, so still shown');
    });

    test('brands follow the same confirmed-empty-only hiding rule', () {
      final qualification = FlipperQualification(
        scannedAt: DateTime.now(),
        qualifyingBrandsByDeviceType: {
          'TVs': {'Samsung'}, // LG scanned and found not to qualify
        },
      );

      final visible = visibleBrands(_tree(), qualification, 'TVs');
      expect(visible, ['Samsung']);
      expect(visible, isNot(contains('LG')));
    });

    test('brands for an unscanned device type are all shown', () {
      final qualification = FlipperQualification(
        scannedAt: DateTime.now(),
        qualifyingBrandsByDeviceType: {'TVs': {'Samsung', 'LG'}},
      );

      final visible = visibleBrands(_tree(), qualification, 'Soundbars');
      expect(visible, ['Sony']);
    });
  });

  group('filterFiles (intersection)', () {
    final files = [
      _file('TVs', 'Samsung'),
      _file('TVs', 'LG'),
      _file('Soundbars', 'Sony'),
    ];

    test('"All" device types and "All" brands keeps everything', () {
      final result = filterFiles(files, const FilterSelection());
      expect(result, hasLength(3));
    });

    test('a single device type narrows to just that type, all brands', () {
      final result = filterFiles(
        files,
        const FilterSelection(deviceTypes: {'TVs'}),
      );
      expect(result.map((f) => f.brand), unorderedEquals(['Samsung', 'LG']));
    });

    test('device type + brand intersect to the matching files', () {
      final result = filterFiles(
        files,
        const FilterSelection(deviceTypes: {'TVs'}, brands: {'Samsung'}),
      );
      expect(result, hasLength(1));
      expect(result.single.brand, 'Samsung');
    });

    test('a non-overlapping device type + brand combination intersects to zero',
        () {
      final result = filterFiles(
        files,
        const FilterSelection(deviceTypes: {'TVs'}, brands: {'Sony'}),
      );
      expect(result, isEmpty);
    });
  });

  group('matchingPowerSignals / matchingMuteSignals', () {
    test('collects one signal per file, skipping files with no match', () {
      final withOneUnmatched = [
        _file('TVs', 'Samsung'),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Vizio',
          fileName: 'v.ir',
          path: 'TVs/Vizio/v.ir',
          signals: const [FlipperIrSignal(name: 'Vol_up')],
        ),
      ];

      expect(matchingPowerSignals(withOneUnmatched), hasLength(1));
      expect(matchingMuteSignals(withOneUnmatched), hasLength(1));
    });

    test('collapses files whose power signal transmits the identical command',
        () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Sony',
          fileName: 'model_a.ir',
          path: 'TVs/Sony/model_a.ir',
          signals: const [
            FlipperIrSignal(
              name: 'Power',
              protocol: 'SIRC',
              protocolParams: {'address': 1, 'command': 21},
            ),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Sony',
          fileName: 'model_b.ir',
          path: 'TVs/Sony/model_b.ir',
          signals: const [
            FlipperIrSignal(
              name: 'Power',
              protocol: 'SIRC',
              // Same command, keys given in a different order — should still
              // dedupe since it's the identical transmission.
              protocolParams: {'command': 21, 'address': 1},
            ),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Sony',
          fileName: 'model_c.ir',
          path: 'TVs/Sony/model_c.ir',
          signals: const [
            FlipperIrSignal(
              name: 'Power',
              protocol: 'SIRC',
              protocolParams: {'address': 1, 'command': 22},
            ),
          ],
        ),
      ];

      final result = matchingPowerSignals(files);
      expect(result, hasLength(2),
          reason: 'model_a and model_b transmit the same command');
    });

    test('collapses files whose raw power signal is byte-for-byte identical',
        () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Generic',
          fileName: 'model_a.ir',
          path: 'TVs/Generic/model_a.ir',
          signals: const [
            FlipperIrSignal(
                name: 'Power', rawData: '9000 4500 560 560', frequencyHz: 38000),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Generic',
          fileName: 'model_b.ir',
          path: 'TVs/Generic/model_b.ir',
          signals: const [
            FlipperIrSignal(
                name: 'Power', rawData: '9000 4500 560 560', frequencyHz: 38000),
          ],
        ),
      ];

      expect(matchingPowerSignals(files), hasLength(1));
    });
  });
}
