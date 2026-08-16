import 'dart:typed_data';

import 'sample_buffer.dart';

/// Channel conversion (Step 34.3).
class ChannelMixer {
  const ChannelMixer();

  SampleBuffer monoToStereo(SampleBuffer mono) {
    final out = Float32List(mono.samples.length * 2);
    for (var i = 0; i < mono.samples.length; i++) {
      out[i * 2] = mono.samples[i];
      out[i * 2 + 1] = mono.samples[i];
    }
    return SampleBuffer(sampleRate: mono.sampleRate, channels: 2, samples: out);
  }

  SampleBuffer stereoToMono(SampleBuffer stereo) {
    final out = Float32List(stereo.frameCount);
    for (var i = 0; i < stereo.frameCount; i++) {
      out[i] = (stereo.samples[i * 2] + stereo.samples[i * 2 + 1]) / 2;
    }
    return SampleBuffer(
      sampleRate: stereo.sampleRate,
      channels: 1,
      samples: out,
    );
  }
}
