import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/labs_diagnostics.dart';

void main() {
  test('logs metadata without retaining input payload', () {
    final diagnostics = LabsDiagnostics();
    diagnostics.record(
      const LabsEvent(
        feature: LabsFeature.gesture,
        outcome: LabsOutcome.accepted,
        payload: 'secret user text',
      ),
    );

    expect(diagnostics.events.single.feature, LabsFeature.gesture);
    expect(diagnostics.events.single.payload, isNull);
    expect(diagnostics.privacyAudit.redactedPayloads, 1);
  });

  test('captures failures without throwing from the boundary', () {
    final diagnostics = LabsDiagnostics();
    final result = diagnostics.guard(
      LabsFeature.voice,
      () => throw StateError('provider unavailable'),
    );

    expect(result.outcome, LabsOutcome.failed);
    expect(diagnostics.metrics.failures, 1);
    expect(diagnostics.events.single.errorType, 'StateError');
  });

  test('reports accepted and rejected metrics', () {
    final diagnostics = LabsDiagnostics();
    diagnostics.record(
      const LabsEvent(feature: LabsFeature.gaze, outcome: LabsOutcome.accepted),
    );
    diagnostics.record(
      const LabsEvent(feature: LabsFeature.gaze, outcome: LabsOutcome.rejected),
    );

    expect(diagnostics.metrics.accepted, 1);
    expect(diagnostics.metrics.rejected, 1);
  });
}
