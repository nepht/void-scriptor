import 'dart:math' as math;

import 'timeline_performance.dart';

/// Waveform peak resolver (Steps 26.45/46/47).
///
/// Waveform peaks are cached at their native resolution; a zoomed-out
/// timeline only needs a fraction of those samples. This resolver derives a
/// requested resolution from cached peaks instead of regenerating them, so
/// switching zoom levels never re-decodes audio. Derivation is lossy at
/// coarser resolutions by design (peaks only, no waveform reconstruction).
class WaveformPeakResolver {
  const WaveformPeakResolver();

  List<double> downsample(
    List<double> source, {
    required WaveformResolution resolution,
  }) {
    if (source.isEmpty) return const [];

    final target = _bucketCount(source.length, resolution);
    if (target >= source.length) return source;

    final result = List<double>.filled(target, 0);
    final bucketSize = source.length / target;
    for (var bucket = 0; bucket < target; bucket++) {
      final start = (bucket * bucketSize).floor();
      final end = math.min(((bucket + 1) * bucketSize).ceil(), source.length);
      var peak = 0.0;
      for (var i = start; i < end; i++) {
        final magnitude = source[i].abs();
        if (magnitude > peak) peak = magnitude;
      }
      result[bucket] = peak;
    }
    return result;
  }

  int _bucketCount(int length, WaveformResolution resolution) =>
      switch (resolution) {
        WaveformResolution.coarse => math.max(1, (length / 16).ceil()),
        WaveformResolution.medium => math.max(1, (length / 4).ceil()),
        WaveformResolution.fine => length,
      };
}
