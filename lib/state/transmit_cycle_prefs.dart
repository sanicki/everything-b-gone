import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-configurable "reaction time" added on top of the transmit cycle's
/// base per-signal delay, so a person watching multiple devices react has
/// more time to notice a result before the next signal fires.
class TransmitCyclePrefs extends ChangeNotifier {
  TransmitCyclePrefs._();

  static final TransmitCyclePrefs instance = TransmitCyclePrefs._();

  static const String _reactionTimeMsKey = 'transmit_cycle_reaction_time_ms_v1';

  /// The cycle's own pacing delay before any reaction time is added.
  static const int baseDelayMs = 700;
  static const int maxReactionTimeMs = 2000;

  int _reactionTimeMs = 0;
  int get reactionTimeMs => _reactionTimeMs;

  /// The delay to pass to [TransmitCycleController.start]'s `delayMs`.
  int get delayMs => baseDelayMs + _reactionTimeMs;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _reactionTimeMs =
          (prefs.getInt(_reactionTimeMsKey) ?? 0).clamp(0, maxReactionTimeMs);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setReactionTimeMs(int value) async {
    final clamped = value.clamp(0, maxReactionTimeMs);
    if (_reactionTimeMs == clamped) return;
    _reactionTimeMs = clamped;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_reactionTimeMsKey, clamped);
    } catch (_) {}
  }
}
