import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/sample_buffer.dart';

/// Audio render context (Step 34.10–34.12).
class AudioRenderContext {
  AudioRenderContext({required this.sampleRate});

  final int sampleRate;

  SampleBuffer renderClip({
    required Float32List samples,
    required double gainDb,
  }) {
    final linear = dbToLinear(gainDb);
    final out = Float32List(samples.length);
    for (var i = 0; i < samples.length; i++) {
      out[i] = samples[i] * linear;
    }
    return SampleBuffer(sampleRate: sampleRate, channels: 1, samples: out);
  }

  Float32List mixdown(List<Float32List> clips) {
    if (clips.isEmpty) return Float32List(0);
    final length = clips.map((c) => c.length).reduce(math.max);
    final out = Float32List(length);
    for (final clip in clips) {
      for (var i = 0; i < clip.length; i++) {
        out[i] += clip[i];
      }
    }
    return out;
  }

  static double dbToLinear(double db) => math.pow(10, db / 20).toDouble();
  static double linearToDb(double linear) => 20 * math.log(linear) / math.ln10;
}
