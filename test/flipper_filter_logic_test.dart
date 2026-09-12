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

    test('matchingPowerBrandSignals pairs each surviving signal with its brand',
        () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'samsung.ir',
          path: 'TVs/Samsung/samsung.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '1 1', frequencyHz: 38000),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'LG',
          fileName: 'lg.ir',
          path: 'TVs/LG/lg.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '2 2', frequencyHz: 38000),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Vizio',
          fileName: 'v.ir',
          path: 'TVs/Vizio/v.ir',
          signals: const [FlipperIrSignal(name: 'Vol_up')],
        ),
      ];

      final result = matchingPowerBrandSignals(files);

      expect(result, hasLength(2), reason: 'Vizio has no power/off signal');
      expect(result.map((m) => m.brand), ['Samsung', 'LG']);
      expect(result.map((m) => m.signal.name), everyElement('Power'));
    });
  });

  group('nextBrandSkipTarget', () {
    test(
        'is a no-op (equals attempted) once the just-sent brand has no more '
        'entries — the common case after dedup, not an edge case', () {
      final brands = ['Samsung', 'LG', 'Sony', 'Vizio'];

      // Samsung already sent (index 0): the next candidate (LG) is already
      // a different brand, so skipping does nothing.
      expect(nextBrandSkipTarget(brands, 1), 1);
      expect(nextBrandSkipTarget(brands, 2), 2);
      expect(nextBrandSkipTarget(brands, 3), 3);
    });

    test('skips every remaining signal that shares the just-sent brand', () {
      final brands = ['Sony', 'Sony', 'Sony', 'LG', 'Vizio'];

      // First Sony signal just sent (index 0); two more Sony entries remain.
      expect(nextBrandSkipTarget(brands, 1), 3);
      // Nothing sent yet, but the upcoming brand (Sony) still has 3 entries
      // — skipping jumps straight past all of them.
      expect(nextBrandSkipTarget(brands, 0), 3);
      // Already past all of Sony's entries: nothing left to skip.
      expect(nextBrandSkipTarget(brands, 3), 3);
    });

    test('skipping the last brand reaches the end of the list', () {
      final brands = ['Sony', 'LG', 'LG'];

      // Sony sent (index 0); now on LG's first entry (index 1) — the last
      // brand in the list, with one more LG entry remaining.
      expect(nextBrandSkipTarget(brands, 2), 3);
      // Already past both LG entries: nothing left to skip.
      expect(nextBrandSkipTarget(brands, 3), 3);
    });
  });
}
