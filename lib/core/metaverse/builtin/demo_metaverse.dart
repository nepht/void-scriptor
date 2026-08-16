import '../world/metaverse_world.dart';
import '../registry/world_registry.dart';

/// Built-in demo metaverse (Step 42.20).
class DemoMetaverse {
  DemoMetaverse._();

  static final WorldRegistry registry = WorldRegistry()
    ..registerWorld(
      const MetaverseWorld(
        id: 'w1',
        name: 'Void Cube',
        description: 'The creative universe',
      ),
    )
    ..registerRegion(
      const WorldRegion(id: 'r1', worldId: 'w1', name: 'The North'),
    )
    ..registerZone(
      const WorldZone(
        id: 'z1',
        regionId: 'r1',
        name: 'Frozen Pole',
        x: 0,
        y: 0,
        z: -2,
      ),
    )
    ..registerZone(
      const WorldZone(
        id: 'z2',
        regionId: 'r1',
        name: 'Volcanic Sea',
        x: 10,
        y: 0,
        z: -2,
      ),
    );
}
