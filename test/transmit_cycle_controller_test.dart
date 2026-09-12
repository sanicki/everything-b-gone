import 'package:flutter_test/flutter_test.dart';
import 'package:everythingbgone/ir/transmit_cycle_controller.dart';

Future<void> pump([int ms = 20]) => Future<void>.delayed(Duration(milliseconds: ms));

void main() {
  group('TransmitCycleController', () {
    test('start() with an empty list is a no-op', () {
      final controller = TransmitCycleController<int>(
        sendCandidate: (_) async {},
      );

      controller.start(<int>[]);

      expect(controller.running, isFalse);
      expect(controller.total, 0);
      expect(controller.attempted, 0);
    });

    test('cycles through every candidate, calling sendCandidate for each',
        () async {
      final sent = <String>[];
      final controller = TransmitCycleController<String>(
        sendCandidate: (c) async {
          sent.add(c);
        },
      );

      controller.start(<String>['a', 'b', 'c'], delayMs: 150);
      expect(controller.running, isTrue);
      expect(controller.total, 3);

      await pump(700);

      expect(sent, <String>['a', 'b', 'c']);
      expect(controller.attempted, 3);
      expect(controller.running, isFalse);
    });

    test('tracks progress as it goes', () async {
      final controller = TransmitCycleController<int>(
        sendCandidate: (_) async {},
      );

      controller.start(<int>[1, 2, 3, 4], delayMs: 150);

      await pump(200);
      expect(controller.attempted, greaterThanOrEqualTo(1));
      expect(controller.attempted, lessThan(4));

      await pump(700);
      expect(controller.attempted, 4);
    });

    test('pause() halts further sends until resume()', () async {
      final sent = <int>[];
      final controller = TransmitCycleController<int>(
        sendCandidate: (c) async => sent.add(c),
      );

      controller.start(<int>[1, 2, 3, 4, 5], delayMs: 150);
      await pump(200);
      final attemptedAtPause = controller.attempted;
      controller.pause();
      expect(controller.paused, isTrue);

      await pump(500);
      expect(controller.attempted, attemptedAtPause,
          reason: 'no more sends should happen while paused');

      controller.resume();
      await pump(800);
      expect(controller.attempted, 5);
    });

    test('stop() ends the run immediately and prevents further sends',
        () async {
      final sent = <int>[];
      final controller = TransmitCycleController<int>(
        sendCandidate: (c) async => sent.add(c),
      );

      controller.start(<int>[1, 2, 3, 4, 5], delayMs: 150);
      await pump(200);
      controller.stop();
      expect(controller.running, isFalse);
      final countAtStop = sent.length;

      await pump(500);
      expect(sent.length, countAtStop,
          reason: 'stop() must prevent any further sends');
    });

    test('an error from sendCandidate is captured without killing the cycle',
        () async {
      final sent = <int>[];
      final controller = TransmitCycleController<int>(
        sendCandidate: (c) async {
          if (c == 2) throw Exception('boom');
          sent.add(c);
        },
      );

      controller.start(<int>[1, 2, 3], delayMs: 150);
      await pump(700);

      expect(sent, <int>[1, 3]);
      expect(controller.attempted, 3);
      expect(controller.running, isFalse);
    });

    test('start() while already running resets progress and restarts',
        () async {
      final controller = TransmitCycleController<int>(
        sendCandidate: (_) async {},
      );

      controller.start(<int>[1, 2, 3, 4, 5], delayMs: 150);
      await pump(200);
      expect(controller.attempted, greaterThan(0));

      controller.start(<int>[10, 20], delayMs: 150);
      expect(controller.attempted, 0);
      expect(controller.total, 2);

      await pump(400);
      expect(controller.attempted, 2);
      expect(controller.running, isFalse);
    });
  });
}
