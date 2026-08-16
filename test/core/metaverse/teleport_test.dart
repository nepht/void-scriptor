import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/metaverse/world/metaverse_world.dart';
import 'package:void_scriptor/core/metaverse/registry/world_registry.dart';
import 'package:void_scriptor/core/metaverse/presence/presence.dart';
import 'package:void_scriptor/core/metaverse/teleport/teleport.dart';

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
    registry.registerZone(
      const WorldZone(
        id: 'z2',
        regionId: 'r1',
        name: 'Volcanic Sea',
        x: 10,
        y: 0,
        z: 0,
      ),
    );
    return registry;
  }

  test('Teleport moves presence to target zone', () {
    final registry = buildRegistry();
    final presence = Presence(avatarId: 'av1', zoneId: 'z1');
    final teleport = Teleport(registry: registry);

    teleport.move(presence, 'z2');
    expect(presence.zoneId, 'z2');
  });

  test('Teleport rejects invalid target zone', () {
    final registry = buildRegistry();
    final presence = Presence(avatarId: 'av1', zoneId: 'z1');
    final teleport = Teleport(registry: registry);

    expect(() => teleport.move(presence, 'missing'), throwsStateError);
    expect(presence.zoneId, 'z1');
  });

  test('Teleport updates presence timestamp', () {
    final registry = buildRegistry();
    var tick = DateTime(2026, 1, 1);
    final presence = Presence(
      avatarId: 'av1',
      zoneId: 'z1',
      now: () => tick,
    );
    final teleport = Teleport(registry: registry);
    final before = presence.lastSeen;

    tick = tick.add(const Duration(seconds: 1));
    teleport.move(presence, 'z2');
    expect(presence.lastSeen, isNot(before));
    expect(presence.lastSeen, tick);
  });
}
