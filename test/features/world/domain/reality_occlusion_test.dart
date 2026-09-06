import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/reality_occlusion.dart';

void main() {
  test('occlusion mask validates dimensions and visibility samples', () {
    const mask = OcclusionMask(
      width: 2,
      height: 2,
      visibleSamples: [true, false, true, false],
    );

    expect(mask.isValid, isTrue);
    expect(mask.visibleRatio, .5);
    expect(mask.isVisibleAt(0), isTrue);
    expect(mask.isVisibleAt(1), isFalse);
  });

  test('unavailable occlusion adapter reports platform boundary', () async {
    const adapter = UnavailableOcclusionAdapter();
    expect(await adapter.start(), OcclusionResult.unavailable);
  });
}
