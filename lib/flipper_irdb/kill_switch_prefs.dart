import 'package:shared_preferences/shared_preferences.dart';

/// Persists the user's current Device Type / Brand filter selection so
/// headless triggers (quick settings tiles, Android Device Controls, the
/// home-screen widget) can fire the same Power/Mute cycle the main screen
/// would compute, without needing the UI open.
///
/// An empty set means "All" for that dimension, matching
/// `FilterSelection`'s convention.
class KillSwitchFilterPrefs {
  KillSwitchFilterPrefs._();

  static const _deviceTypesKey = 'killswitch.filter.deviceTypes.v1';
  static const _brandsKey = 'killswitch.filter.brands.v1';

  static Future<Set<String>> loadDeviceTypes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_deviceTypesKey) ?? const <String>[]).toSet();
  }

  static Future<Set<String>> loadBrands() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_brandsKey) ?? const <String>[]).toSet();
  }

  static Future<void> save({
    required Set<String> deviceTypes,
    required Set<String> brands,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_deviceTypesKey, deviceTypes.toList());
    await prefs.setStringList(_brandsKey, brands.toList());
  }
}
