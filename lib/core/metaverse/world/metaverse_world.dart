/// A metaverse world (Step 42.1).
class MetaverseWorld {
  const MetaverseWorld({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;
}

/// A region within a world (Step 42.2).
class WorldRegion {
  const WorldRegion({
    required this.id,
    required this.worldId,
    required this.name,
  });

  final String id;
  final String worldId;
  final String name;
}

/// A zone within a region (Step 42.3).
class WorldZone {
  const WorldZone({
    required this.id,
    required this.regionId,
    required this.name,
    required this.x,
    required this.y,
    required this.z,
  });

  final String id;
  final String regionId;
  final String name;
  final double x;
  final double y;
  final double z;
}
