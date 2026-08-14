import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/performance/timeline_performance.dart';

void main() {
  test('timeline viewport expands visible range by overscan', () {
    const viewport = TimelineViewport(
      startSeconds: 10,
      endSeconds: 20,
      pixelsPerSecond: 50,
      overscanSeconds: 2,
    );
    expect(viewport.queryStart, 8);
    expect(viewport.queryEnd, 22);
  });

  test('timeline clip query returns only intersecting clips', () {
    const viewport = TimelineViewport(
      startSeconds: 10,
      endSeconds: 20,
      pixelsPerSecond: 50,
      overscanSeconds: 0,
    );
    const clips = [
      TimelineClipBounds(id: 'before', start: 0, end: 9),
      TimelineClipBounds(id: 'visible', start: 9, end: 11),
      TimelineClipBounds(id: 'after', start: 20, end: 21),
      TimelineClipBounds(id: 'far', start: 30, end: 31),
    ];
    expect(viewport.visibleClipIds(clips), ['visible', 'after']);
  });

  test('waveform resolution follows zoom level', () {
    expect(WaveformResolution.forPixelsPerSecond(2), WaveformResolution.coarse);
    expect(
      WaveformResolution.forPixelsPerSecond(20),
      WaveformResolution.medium,
    );
    expect(WaveformResolution.forPixelsPerSecond(100), WaveformResolution.fine);
  });
}
