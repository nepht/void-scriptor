import '../world/metaverse_world.dart';

/// World registry: worlds, regions, zones (Step 42.7–42.9).
class WorldRegistry {
  final Map<String, MetaverseWorld> _worlds = {};
  final Map<String, WorldRegion> _regions = {};
  final Map<String, WorldZone> _zones = {};

  void registerWorld(MetaverseWorld world) => _worlds[world.id] = world;

  void registerRegion(WorldRegion region) => _regions[region.id] = region;

  void registerZone(WorldZone zone) => _zones[zone.id] = zone;

  List<WorldRegion> regionsOfWorld(String worldId) => [
    for (final region in _regions.values)
      if (region.worldId == worldId) region,
  ];

  List<WorldZone> zonesOfRegion(String regionId) => [
    for (final zone in _zones.values)
      if (zone.regionId == regionId) zone,
  ];

  WorldZone? zone(String id) => _zones[id];

  int get worldCount => _worlds.length;
  int get zoneCount => _zones.length;
}
