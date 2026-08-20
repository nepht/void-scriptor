import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/dwell_selection.dart';

void main() {
  test('selects after stable dwell reaches the threshold', () {
    const selector = DwellSelector(dwellDuration: Duration(milliseconds: 500));

    final result = selector.evaluate(
      const DwellSample(
        targetId: 'scene-1',
        confidence: .9,
        stableFor: Duration(milliseconds: 600),
      ),
    );

    expect(result.selectedTargetId, 'scene-1');
    expect(result.shouldActivate, isTrue);
  });

  test('does not select while moving or before the dwell threshold', () {
    const selector = DwellSelector(dwellDuration: Duration(milliseconds: 500));

    expect(
      selector
          .evaluate(
            const DwellSample(
              targetId: 'scene-1',
              confidence: .9,
              stableFor: Duration(milliseconds: 600),
              isStable: false,
            ),
          )
          .selectedTargetId,
      isNull,
    );
    expect(
      selector
          .evaluate(
            const DwellSample(
              targetId: 'scene-1',
              confidence: .9,
              stableFor: Duration(milliseconds: 300),
            ),
          )
          .selectedTargetId,
      isNull,
    );
  });

  test('rejects confidence below the actionable threshold', () {
    const selector = DwellSelector();

    final result = selector.evaluate(
      const DwellSample(
        targetId: 'scene-1',
        confidence: .69,
        stableFor: Duration(milliseconds: 700),
      ),
    );

    expect(result.selectedTargetId, isNull);
    expect(result.shouldActivate, isFalse);
  });
}
