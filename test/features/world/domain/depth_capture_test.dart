import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/depth_capture.dart';

void main() {
  test('depth frame validates samples and exposes bounded statistics', () {
    const frame = DepthFrame(
      width: 2,
      height: 2,
      samplesMeters: [1, 2, 3, 4],
      minReliableMeters: .2,
      maxReliableMeters: 5,
    );

    expect(frame.isValid, isTrue);
    expect(frame.sampleCount, 4);
    expect(frame.averageMeters, 2.5);
    expect(frame.reliableSamples, [1, 2, 3, 4]);
  });

  test(
    'unavailable depth adapter reports hardware boundary explicitly',
    () async {
      const adapter = UnavailableDepthAdapter();

      expect(await adapter.start(), DepthCaptureResult.unavailable);
      expect(await adapter.stop(), DepthCaptureResult.stopped);
    },
  );
}
