import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/domain/universe.dart';

void main() {
  group('UniverseTypes', () {
    test('exposes canonical universe types', () {
      expect(UniverseType.values.map((e) => e.name), [
        'canon',
        'alternate',
        'whatIf',
        'spinOff',
        'au',
        'crossover',
        'parallel',
        'dream',
      ]);
    });
  });

  group('Universe', () {
    test('creates with identity fields', () {
      final u = Universe(
        id: 'u1',
        name: 'Void Cube Saga',
        type: UniverseType.canon,
        description: 'Main narrative timeline',
      );
      expect(u.name, 'Void Cube Saga');
      expect(u.type, UniverseType.canon);
      expect(u.isPrimary, isFalse);
    });

    test('marks primary canonicity', () {
      final u = Universe(
        id: 'u1',
        name: 'Primary',
        type: UniverseType.canon,
        isPrimary: true,
      );
      expect(u.isPrimary, isTrue);
    });

    test('copyWith preserves identity', () {
      final u = Universe(id: 'u1', name: 'Before', type: UniverseType.au);
      final updated = u.copyWith(name: 'After', type: UniverseType.canon);
      expect(updated.name, 'After');
      expect(updated.type, UniverseType.canon);
      expect(updated.id, 'u1');
    });
  });

  group('UniverseContext', () {
    test('holds active universe and switching state', () {
      const ctx = UniverseContext(
        activeUniverseId: 'u1',
        previousUniverseId: 'u2',
      );
      expect(ctx.activeUniverseId, 'u1');
      expect(ctx.previousUniverseId, 'u2');
    });
  });
}
