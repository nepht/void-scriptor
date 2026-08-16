import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/audio_engine/dsp/sample_buffer.dart';
import 'package:void_scriptor/core/audio_engine/dsp/resampler.dart';
import 'package:void_scriptor/core/audio_engine/dsp/channel_mixer.dart';

void main() {
  test('SampleBuffer exposes dimensions and channels', () {
    final buf = SampleBuffer(
      sampleRate: 48000,
      channels: 2,
      samples: Float32List(8),
    );
    expect(buf.sampleRate, 48000);
    expect(buf.channels, 2);
    expect(buf.frameCount, 4); // 8 samples / 2 channels
  });

  test('Resampler linear interpolates', () {
    const resampler = Resampler();
    final input = Float32List.fromList([0, 1, 0]);
    final output = resampler.resample(
      input: input,
      inputRate: 3,
      outputRate: 6,
    );
    // 3 samples at 3Hz → 6 samples at 6Hz; midpoint should be ~0.5
    expect(output.length, 6);
    expect(output[1], closeTo(0.5, 1e-6));
  });

  test('ChannelMixer mono to stereo duplicates', () {
    const mixer = ChannelMixer();
    final mono = SampleBuffer(
      sampleRate: 48000,
      channels: 1,
      samples: Float32List.fromList([1, 2]),
    );
    final stereo = mixer.monoToStereo(mono);
    expect(stereo.channels, 2);
    expect(stereo.samples.length, 4);
    expect(stereo.samples[0], 1);
    expect(stereo.samples[1], 1);
  });

  test('ChannelMixer stereo to mono averages', () {
    const mixer = ChannelMixer();
    final stereo = SampleBuffer(
      sampleRate: 48000,
      channels: 2,
      samples: Float32List.fromList([2, 4, 6, 8]),
    );
    final mono = mixer.stereoToMono(stereo);
    expect(mono.channels, 1);
    expect(mono.samples.length, 2);
    expect(mono.samples[0], 3); // (2+4)/2
    expect(mono.samples[1], 7); // (6+8)/2
  });
}
