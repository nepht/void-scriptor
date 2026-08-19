import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/intent/domain/interaction_input.dart';

void main() {
  test('normalizes an interaction event without losing provenance', () {
    final event = InteractionEvent(
      id: 'evt-1',
      type: InteractionInputType.voice,
      payload: '  Buat   project baru  ',
      confidence: 0.82,
      timestamp: DateTime.utc(2026, 1, 1),
    );

    final normalized = NormalizedInput.fromEvent(event);

    expect(normalized.eventId, 'evt-1');
    expect(normalized.type, InteractionInputType.voice);
    expect(normalized.text, 'buat project baru');
    expect(normalized.confidence, 0.82);
    expect(normalized.timestamp, event.timestamp);
  });

  test('clamps invalid confidence and rejects blank payload', () {
    expect(
      () => InteractionEvent(
        id: 'evt-2',
        type: InteractionInputType.touch,
        payload: '   ',
      ),
      throwsArgumentError,
    );

    final event = InteractionEvent(
      id: 'evt-3',
      type: InteractionInputType.gesture,
      payload: 'tap',
      confidence: 4,
    );
    expect(event.confidence, 1);
  });
}

extension on NormalizedInput {
  DateTime get timestamp => sourceTimestamp;
}
