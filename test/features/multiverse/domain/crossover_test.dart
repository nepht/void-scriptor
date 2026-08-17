import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/multiverse/domain/crossover.dart';

void main() {
  group('UniverseBridge', () {
    test('connects two universes with rules', () {
      const bridge = UniverseBridge(
        id: 'b1',
        fromUniverseId: 'u1',
        toUniverseId: 'u2',
        rules: [
          BridgeRule(ruleId: 'r1', description: 'Only canon entities cross'),
        ],
      );
      expect(bridge.fromUniverseId, 'u1');
      expect(bridge.toUniverseId, 'u2');
      expect(bridge.rules.single.ruleId, 'r1');
    });
  });

  group('CrossoverEvent', () {
    test('records crossover occurrence', () {
      final ev = CrossoverEvent(
        id: 'c1',
        projectId: 'p1',
        universeIds: ['u1', 'u2'],
        occurredAt: DateTime.utc(2026, 1, 1),
        description: 'Qowner meets the Void Warden',
      );
      expect(ev.universeIds, ['u1', 'u2']);
      expect(ev.description, contains('Void Warden'));
    });
  });

  group('CrossoverStatePackage', () {
    test('packages return state', () {
      const pkg = CrossoverStatePackage(
        id: 'pkg1',
        entityId: 'char1',
        originUniverseId: 'u1',
        stateData: {'power': 100},
      );
      expect(pkg.originUniverseId, 'u1');
      expect(pkg.stateData['power'], 100);
    });
  });

  group('CanonStatus', () {
    test('canon status ordering', () {
      expect(CanonStatus.values.map((e) => e.name), [
        'canon',
        'softCanon',
        'semiCanon',
        'nonCanon',
      ]);
    });
  });
}
