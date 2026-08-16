import 'dart:typed_data';

/// Linear resampler (Step 34.2).
class Resampler {
  const Resampler();

  Float32List resample({
    required Float32List input,
    required int inputRate,
    required int outputRate,
  }) {
    if (input.isEmpty) return Float32List(0);
    if (inputRate == outputRate) return Float32List.fromList(input);

    final ratio = inputRate / outputRate;
    final outputLength = (input.length / ratio).ceil();
    final output = Float32List(outputLength);

    for (var i = 0; i < outputLength; i++) {
      final position = i * ratio;
      final index = position.floor();
      final frac = position - index;
      final a = input[index];
      final b = input[(index + 1).clamp(0, input.length - 1)];
      output[i] = a + (b - a) * frac;
    }
    return output;
  }
}
