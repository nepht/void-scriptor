import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/metaverse/world/metaverse_world.dart';
import 'package:void_scriptor/core/metaverse/registry/world_registry.dart';

void main() {
  WorldRegistry buildRegistry() {
    final registry = WorldRegistry();
    registry.registerWorld(
      const MetaverseWorld(
        id: 'w1',
        name: 'Void Cube',
        description: 'universe',
      ),
    );
    registry.registerRegion(
      const WorldRegion(id: 'r1', worldId: 'w1', name: 'The North'),
    );
    registry.registerZone(
      const WorldZone(
        id: 'z1',
        regionId: 'r1',
        name: 'Frozen Pole',
        x: 0,
        y: 0,
        z: 0,
      ),
    );
    return registry;
  }

  test('WorldRegistry queries regions by world', () {
    final registry = buildRegistry();
    expect(registry.regionsOfWorld('w1'), hasLength(1));
    expect(registry.regionsOfWorld('missing'), isEmpty);
  });

  test('WorldRegistry queries zones by region', () {
    final registry = buildRegistry();
    expect(registry.zonesOfRegion('r1'), hasLength(1));
  });

  test('WorldRegistry zone lookup by id', () {
    final registry = buildRegistry();
    expect(registry.zone('z1')!.name, 'Frozen Pole');
    expect(registry.zone('missing'), isNull);
  });
}
