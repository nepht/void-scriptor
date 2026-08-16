import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/audio_engine/pipeline/audio_render_context.dart';

void main() {
  test('AudioRenderContext evaluates single clip to buffer', () {
    final ctx = AudioRenderContext(sampleRate: 48000);
    final buf = ctx.renderClip(
      samples: Float32List.fromList([1, 2, 3, 4]),
      gainDb: 0,
    );
    expect(buf.sampleRate, 48000);
    expect(buf.samples, hasLength(4));
    expect(buf.samples[0], 1);
  });

  test('AudioRenderContext applies gain', () {
    final ctx = AudioRenderContext(sampleRate: 48000);
    final buf = ctx.renderClip(
      samples: Float32List.fromList([1, 2, 3, 4]),
      gainDb: -6.0206, // ≈ 0.5 linear
    );
    expect(buf.samples[0], closeTo(0.5, 1e-3));
  });

  test('AudioRenderContext mixdown sums overlapping clips', () {
    final ctx = AudioRenderContext(sampleRate: 48000);
    final out = ctx.mixdown([
      Float32List.fromList([1, 0, 0, 0]),
      Float32List.fromList([0, 2, 0, 0]),
    ]);
    expect(out, hasLength(4));
    expect(out[0], closeTo(1, 1e-6));
    expect(out[1], closeTo(2, 1e-6));
  });
}
