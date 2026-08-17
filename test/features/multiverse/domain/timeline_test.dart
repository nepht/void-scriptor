import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/domain/timeline.dart';

void main() {
  group('Timeline', () {
    test('creates with branch info', () {
      final t = Timeline(
        id: 't1',
        universeId: 'u1',
        name: 'Mainline',
        branchOf: null,
      );
      expect(t.universeId, 'u1');
      expect(t.branchOf, isNull);
      expect(t.isAlternate, isFalse);
    });

    test('branch marks alternate timeline', () {
      final branch = Timeline(
        id: 't2',
        universeId: 'u1',
        name: 'What If',
        branchOf: 't1',
      );
      expect(branch.isAlternate, isTrue);
      expect(branch.branchOf, 't1');
    });

    test('copyWith updates name', () {
      final t = Timeline(id: 't1', universeId: 'u1', name: 'Old');
      expect(t.copyWith(name: 'New').name, 'New');
    });
  });

  group('DivergenceEvent', () {
    test('records divergence point', () {
      const d = DivergenceEvent(
        id: 'd1',
        timelineId: 't2',
        sourceTimelineId: 't1',
        description: 'The Void Cube shatters early',
        atChapterSceneId: 'c1',
      );
      expect(d.sourceTimelineId, 't1');
      expect(d.description, contains('shatters'));
    });
  });

  group('TemporalState', () {
    test('holds character state at time', () {
      final s = TemporalState(
        id: 's1',
        timelineId: 't1',
        entityId: 'char1',
        timestamp: DateTime.utc(2026, 1, 1),
        stateData: {'age': 20, 'alive': true},
      );
      expect(s.stateData['age'], 20);
      expect(s.entityId, 'char1');
    });
  });
}
