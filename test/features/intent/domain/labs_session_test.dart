import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/labs_session.dart';

void main() {
  test('isolates experiments by session and prevents replay', () {
    final session = LabsSession(sessionId: 's-1');
    session.record(const LabsAction(id: 'a-1', feature: 'gesture'));

    expect(session.hasSeen('a-1'), isTrue);
    expect(session.replay('a-1'), isFalse);
    expect(session.replay('a-2'), isFalse);
  });

  test('registry accepts compatible experiments only', () {
    final registry = ExperimentRegistry(currentVersion: '0.51');
    registry.register(const Experiment(id: 'gesture', version: '0.51'));
    registry.register(const Experiment(id: 'future', version: '0.60'));

    expect(registry.isCompatible('gesture'), isTrue);
    expect(registry.isCompatible('future'), isFalse);
  });
}
