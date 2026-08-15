import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/timeline_performance.dart';
import 'package:void_scriptor/core/performance/waveform_peak_resolver.dart';

void main() {
  test('selects resolution for zoom level', () {
    expect(WaveformResolution.forPixelsPerSecond(5), WaveformResolution.coarse);
    expect(
      WaveformResolution.forPixelsPerSecond(25),
      WaveformResolution.medium,
    );
    expect(WaveformResolution.forPixelsPerSecond(80), WaveformResolution.fine);
  });

  test('downsamples fine peaks to a requested resolution', () {
    const resolver = WaveformPeakResolver();
    final fine = List.generate(100, (i) => (i % 2 == 0 ? 1.0 : -1.0));

    final coarse = resolver.downsample(
      fine,
      resolution: WaveformResolution.coarse,
    );
    expect(coarse.length, lessThan(fine.length));
    expect(coarse.every((v) => v >= -1 && v <= 1), isTrue);
  });

  test('upsampling a finer resolution than available caps at source', () {
    const resolver = WaveformPeakResolver();
    final coarse = [1.0, -1.0, 1.0];

    final fine = resolver.downsample(
      coarse,
      resolution: WaveformResolution.fine,
    );
    expect(fine.length, coarse.length);
  });

  test('empty peaks return empty list', () {
    const resolver = WaveformPeakResolver();
    expect(
      resolver.downsample(const [], resolution: WaveformResolution.fine),
      isEmpty,
    );
  });
}
