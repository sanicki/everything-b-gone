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

  group('buildSignalListGroups', () {
    test('groups by device type then brand, both sorted alphabetically', () {
      final files = [
        _file('Soundbars', 'Sony'),
        _file('TVs', 'LG'),
        _file('TVs', 'Samsung'),
      ];

      final groups = buildSignalListGroups(files);
      expect(groups.map((g) => g.deviceType), ['Soundbars', 'TVs']);
      expect(groups.last.rows.map((r) => r.brand), ['LG', 'Samsung']);
    });

    test('a lone file for a brand gets no option label', () {
      final groups = buildSignalListGroups([_file('TVs', 'Samsung')]);
      expect(groups.single.rows.single.optionLabel, isNull);
    });

    test('multiple distinct-signal files for the same brand are numbered by '
        'file name order', () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_b.ir',
          path: 'TVs/Samsung/model_b.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '200 200', frequencyHz: 38000),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_a.ir',
          path: 'TVs/Samsung/model_a.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '100 100', frequencyHz: 38000),
          ],
        ),
      ];

      final rows = buildSignalListGroups(files).single.rows;
      expect(rows, hasLength(2));
      expect(rows[0].file.fileName, 'model_a.ir');
      expect(rows[0].optionLabel, 'Option 1');
      expect(rows[1].file.fileName, 'model_b.ir');
      expect(rows[1].optionLabel, 'Option 2');
    });

    test('a file with neither a power/off nor a mute signal is skipped', () {
      final files = [
        _file('TVs', 'Samsung'),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Vizio',
          fileName: 'v.ir',
          path: 'TVs/Vizio/v.ir',
          signals: const [FlipperIrSignal(name: 'Vol_up')],
        ),
      ];

      final rows = buildSignalListGroups(files).single.rows;
      expect(rows, hasLength(1));
      expect(rows.single.brand, 'Samsung');
    });

    test('option numbering is recomputed from the survivors after skipping '
        'a no-signal file, so a lone survivor gets no label', () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_a.ir',
          path: 'TVs/Samsung/model_a.ir',
          signals: const [FlipperIrSignal(name: 'Vol_up')], // no power/mute
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_b.ir',
          path: 'TVs/Samsung/model_b.ir',
          signals: const [FlipperIrSignal(name: 'Power')],
        ),
      ];

      final rows = buildSignalListGroups(files).single.rows;
      expect(rows, hasLength(1));
      expect(rows.single.file.fileName, 'model_b.ir');
      expect(rows.single.optionLabel, isNull,
          reason: 'only one row survives for this brand, so no "Option N" '
              'suffix is needed');
    });

    test('rows sharing a Brand with the identical Power and Mute signal are '
        'de-duped, keeping the first in file-name order', () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_b.ir',
          path: 'TVs/Samsung/model_b.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '100 100', frequencyHz: 38000),
            FlipperIrSignal(name: 'Mute', rawData: '200 200', frequencyHz: 38000),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_a.ir',
          path: 'TVs/Samsung/model_a.ir',
          // Identical Power and Mute transmissions as model_b, just a
          // different file name — this is the duplicate to collapse.
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '100 100', frequencyHz: 38000),
            FlipperIrSignal(name: 'Mute', rawData: '200 200', frequencyHz: 38000),
          ],
        ),
      ];

      final rows = buildSignalListGroups(files).single.rows;
      expect(rows, hasLength(1));
      expect(rows.single.file.fileName, 'model_a.ir',
          reason: 'first survivor in file-name order is kept');
      expect(rows.single.optionLabel, isNull);
    });

    test('same Brand + same Power but a different Mute is NOT de-duped', () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_a.ir',
          path: 'TVs/Samsung/model_a.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '100 100', frequencyHz: 38000),
            FlipperIrSignal(name: 'Mute', rawData: '200 200', frequencyHz: 38000),
          ],
        ),
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'model_b.ir',
          path: 'TVs/Samsung/model_b.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '100 100', frequencyHz: 38000),
            FlipperIrSignal(name: 'Mute', rawData: '999 999', frequencyHz: 38000),
          ],
        ),
      ];

      final rows = buildSignalListGroups(files).single.rows;
      expect(rows, hasLength(2));
      expect(rows[0].optionLabel, 'Option 1');
      expect(rows[1].optionLabel, 'Option 2');
    });

    test('de-duping is scoped per Device Type: identical Brand+Power+Mute in '
        'a different Device Type is kept', () {
      final files = [
        FlipperIrFile(
          deviceType: 'TVs',
          brand: 'Samsung',
          fileName: 'a.ir',
          path: 'TVs/Samsung/a.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '100 100', frequencyHz: 38000),
            FlipperIrSignal(name: 'Mute', rawData: '200 200', frequencyHz: 38000),
          ],
        ),
        FlipperIrFile(
          deviceType: 'Soundbars',
          brand: 'Samsung',
          fileName: 'a.ir',
          path: 'Soundbars/Samsung/a.ir',
          signals: const [
            FlipperIrSignal(name: 'Power', rawData: '100 100', frequencyHz: 38000),
            FlipperIrSignal(name: 'Mute', rawData: '200 200', frequencyHz: 38000),
          ],
        ),
      ];

      final groups = buildSignalListGroups(files);
      expect(groups, hasLength(2));
      expect(groups[0].rows, hasLength(1));
      expect(groups[1].rows, hasLength(1));
    });

    test('a device type with zero qualifying rows is omitted entirely', () {
      final files = [
        FlipperIrFile(
          deviceType: 'Fans',
          brand: 'Generic',
          fileName: 'f.ir',
          path: 'Fans/Generic/f.ir',
          signals: const [FlipperIrSignal(name: 'Speed')],
        ),
        _file('TVs', 'Samsung'),
      ];

      final groups = buildSignalListGroups(files);
      expect(groups.map((g) => g.deviceType), ['TVs']);
    });

    test('power and mute signals on a row match powerOrOffSignalFor/muteSignalFor',
        () {
      final rows = buildSignalListGroups([_file('TVs', 'Samsung')]).single.rows;
      expect(rows.single.powerSignal?.name, 'Power');
      expect(rows.single.muteSignal?.name, 'Mute');
    });
  });
}
