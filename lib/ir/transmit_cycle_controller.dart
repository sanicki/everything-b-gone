import 'dart:async';

import 'package:flutter/foundation.dart';

/// Sends a single candidate signal through whichever transmitter is
/// currently active. Implementations are expected to route through the
/// existing platform transmit pipeline (e.g. `transmitRaw` in
/// `lib/utils/ir.dart`), which already applies frequency clamping and
/// pattern validation — this controller has no protocol- or
/// transmitter-specific knowledge of its own.
typedef TransmitCandidateSender<T> = Future<void> Function(T candidate);

/// Cycles through a fixed list of candidate signals, sending each one in
/// turn with a delay in between, and tracks progress so a screen can show a
/// "Stop" control mid-run.
///
/// This is a narrower extraction of the upstream Signal Tester's
/// `IrFinderRunController`: same start/pause/resume/stop/timer-tick shape,
/// with the brute-force/database-search-specific configuration removed
/// since Everything-B-Gone always cycles a concrete, already-computed list
/// of matching signals rather than searching a space.
class TransmitCycleController<T> extends ChangeNotifier {
  final TransmitCandidateSender<T> sendCandidate;

  TransmitCycleController({required this.sendCandidate});

  List<T> _candidates = const [];
  int delayMs = 700;

  bool running = false;
  bool paused = false;
  int attempted = 0;
  T? lastCandidate;
  Object? lastError;

  Timer? _timer;
  bool _tickBusy = false;

  int get total => _candidates.length;
  bool get isDone => running == false && attempted > 0 && attempted >= total;

  /// Starts (or restarts) a cycle over [candidates]. A no-op if the list is
  /// empty — callers should check `total > 0` before showing a Stop control.
  void start(List<T> candidates, {int? delayMs}) {
    _cancelTimer();
    _candidates = candidates;
    if (delayMs != null) {
      this.delayMs = delayMs.clamp(150, 20000);
    }
    attempted = 0;
    lastCandidate = null;
    lastError = null;
    running = _candidates.isNotEmpty;
    paused = false;
    notifyListeners();
    if (!running) return;
    _scheduleTimer();
  }

  void pause() {
    if (!running || paused) return;
    paused = true;
    _cancelTimer();
    notifyListeners();
  }

  void resume() {
    if (!running || !paused) return;
    paused = false;
    notifyListeners();
    _scheduleTimer();
  }

  void stop() {
    if (!running && !paused) return;
    _cancelTimer();
    running = false;
    paused = false;
    notifyListeners();
  }

  /// Jumps the cycle directly to [index] (clamped to `[attempted, total]`),
  /// skipping every candidate in between without sending them, and
  /// reschedules so the candidate now at [index] fires after the normal
  /// delay like any other tick. A no-op while not actively running, or if
  /// [index] doesn't move the cursor forward. Passing `total` ends the run.
  ///
  /// Callers decide what "skip" means for their candidate type (e.g. "skip
  /// to the next brand") — this controller has no domain knowledge of `T`.
  void skipTo(int index) {
    if (!running || paused) return;
    final clamped = index.clamp(attempted, _candidates.length);
    if (clamped == attempted) return;
    attempted = clamped;
    notifyListeners();
    if (attempted >= _candidates.length) {
      stop();
      return;
    }
    _scheduleTimer();
  }

  void _scheduleTimer() {
    _cancelTimer();
    if (!running || paused) return;
    _timer = Timer.periodic(Duration(milliseconds: delayMs), (_) {
      unawaited(_tick());
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (!running || paused) return;
    if (_tickBusy) return;
    if (attempted >= _candidates.length) {
      stop();
      return;
    }

    _tickBusy = true;
    try {
      final candidate = _candidates[attempted];
      Object? err;
      try {
        await sendCandidate(candidate);
      } catch (e) {
        err = e;
      }

      lastCandidate = candidate;
      lastError = err;
      attempted += 1;
      notifyListeners();

      if (attempted >= _candidates.length) {
        stop();
      }
    } finally {
      _tickBusy = false;
    }
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }
}
