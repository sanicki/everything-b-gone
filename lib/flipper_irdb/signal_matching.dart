import 'flipper_irdb_models.dart';

/// Picks the best power-off signal from a parsed `.ir` file: a
/// case-insensitive substring match on "power" wins whenever one exists;
/// only when no signal in the file is power-named do we fall back to an
/// "off"-named one. Returns null if the file has neither.
///
/// This precedence matters: a file can plausibly have both a "Power"
/// toggle and an "Off"-only signal (e.g. a discrete on/off remote), and
/// picking the wrong one silently sends the wrong signal, so it's covered
/// by direct tests rather than left to fall out of iteration order.
FlipperIrSignal? powerOrOffSignalFor(FlipperIrFile file) {
  for (final signal in file.signals) {
    if (signal.name.toLowerCase().contains('power')) return signal;
  }
  for (final signal in file.signals) {
    if (signal.name.toLowerCase().contains('off')) return signal;
  }
  return null;
}

/// The first "mute"-named signal in the file, or null if it has none.
FlipperIrSignal? muteSignalFor(FlipperIrFile file) {
  for (final signal in file.signals) {
    if (signal.name.toLowerCase().contains('mute')) return signal;
  }
  return null;
}
