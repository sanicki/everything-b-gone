import 'package:everythingbgone/flipper_irdb/flipper_irdb_models.dart';
import 'package:everythingbgone/ir/ir_protocol_registry.dart';
import 'package:everythingbgone/utils/ir.dart';

/// Transmits a single parsed Flipper-IRDB signal through whichever
/// transmitter is currently active, routing through the shared
/// `transmitRaw` pipeline (frequency clamping, pattern validation) exactly
/// like every other IR send in the app.
Future<void> transmitFlipperSignal(FlipperIrSignal signal) async {
  if (signal.isRaw) {
    final pattern = signal.rawData!
        .trim()
        .split(RegExp(r'\s+'))
        .map(int.parse)
        .toList(growable: false);
    await transmitRaw(signal.frequencyHz ?? 38000, pattern);
    return;
  }
  final encoder = IrProtocolRegistry.encoderFor(signal.protocol!);
  final result =
      encoder.encode(signal.protocolParams ?? const <String, dynamic>{});
  await transmitRaw(result.frequencyHz, result.pattern);
}
