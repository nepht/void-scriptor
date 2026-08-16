import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/metaverse/world/metaverse_world.dart';

void main() {
  test('MetaverseWorld holds identity', () {
    const world = MetaverseWorld(
      id: 'w1',
      name: 'Void Cube',
      description: 'The creative universe',
    );
    expect(world.name, 'Void Cube');
    expect(world.description, 'The creative universe');
  });

  test('WorldRegion holds world reference', () {
    const region = WorldRegion(id: 'r1', worldId: 'w1', name: 'The North');
    expect(region.worldId, 'w1');
    expect(region.name, 'The North');
  });

  test('WorldZone holds position', () {
    const zone = WorldZone(
      id: 'z1',
      regionId: 'r1',
      name: 'Frozen Pole',
      x: 1.0,
      y: 0.0,
      z: -2.0,
    );
    expect(zone.name, 'Frozen Pole');
    expect(zone.x, 1.0);
  });
}
