import 'dart:typed_data';

/// Float32 audio sample buffer (Step 34.1).
class SampleBuffer {
  SampleBuffer({
    required this.sampleRate,
    required this.channels,
    required this.samples,
  });

  final int sampleRate;
  final int channels;
  final Float32List samples;

  int get frameCount => samples.length ~/ channels;
}
