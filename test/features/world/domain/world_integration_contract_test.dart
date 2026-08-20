import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/world/domain/world_integration_contract.dart';

void main() {
  test('editor integrates geography effects, travel, and global wind', () {
    final world = WorldIntegrationContract();
    expect(
      world.editorModules,
      containsAll(<String>['planet', 'terrain', 'climate', 'streaming']),
    );
    world.setWind(const WindVector(x: 1, y: 0));
    expect(world.travelCost(distanceKm: 100, againstWind: false), 100);
    expect(world.travelCost(distanceKm: 100, againstWind: true), 120);
    expect(world.geographyEffect('volcano'), contains('terrain'));
  });

  test('destruction persists and repair is bounded', () {
    final world = WorldIntegrationContract();
    world.destroy('bridge', severity: 8);
    expect(world.isDestroyed('bridge'), isTrue);
    world.repair('bridge', amount: 3);
    expect(world.damageOf('bridge'), 5);
    world.repair('bridge', amount: 10);
    expect(world.damageOf('bridge'), 0);
  });

  test(
    'planet designer uses preview-first deterministic natural language output',
    () {
      const designer = PlanetDesignerAi();
      final preview = designer.preview('a volcanic island with two moons');
      expect(preview.isPreview, isTrue);
      expect(preview.seed, isNotNull);
      expect(
        designer.preview('a volcanic island with two moons').seed,
        preview.seed,
      );
    },
  );
}
