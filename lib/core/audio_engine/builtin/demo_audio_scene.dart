import 'dart:math' as math;
import 'dart:typed_data';

import '../pipeline/audio_render_context.dart';
import '../bus/audio_bus.dart';

/// Built-in demo audio scene proving the DSP pipeline end-to-end (Step 34.20).
class DemoAudioScene {
  DemoAudioScene._();

  static final AudioRenderContext context = AudioRenderContext(
    sampleRate: 48000,
  );

  static const List<AudioBus> buses = [
    AudioBus(name: 'music', gainDb: -6),
    AudioBus(name: 'dialogue', gainDb: 0),
    AudioBus(name: 'sfx', gainDb: -12),
  ];

  static Float32List renderDemo() {
    // A simple 1kHz sine burst as a synthetic "tone" clip.
    final tone = Float32List(48000);
    for (var i = 0; i < tone.length; i++) {
      tone[i] = math.sin(i / 48000 * 1000 * 2 * math.pi) * 0.5;
    }
    return context.mixdown([
      context.renderClip(samples: tone, gainDb: -6).samples,
    ]);
  }
}
