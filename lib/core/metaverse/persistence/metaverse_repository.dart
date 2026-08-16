import '../../../database/project/project_database.dart';

/// Persists metaverse worlds and zones (Step 42.15).
class MetaverseRepository {
  MetaverseRepository({required this.database});

  final ProjectDatabase database;

  Future<void> saveWorld({
    required String id,
    required String name,
    required String description,
  }) async {
    await database
        .into(database.metaverseWorlds)
        .insertOnConflictUpdate(
          MetaverseWorldsCompanion.insert(
            id: id,
            name: name,
            description: description,
          ),
        );
  }

  Future<List<MetaverseWorld>> listWorlds() async =>
      database.select(database.metaverseWorlds).get();

  Future<void> saveZone({
    required String id,
    required String worldId,
    required String regionId,
    required String name,
    required double x,
    required double y,
    required double z,
  }) async {
    await database
        .into(database.metaverseZones)
        .insertOnConflictUpdate(
          MetaverseZonesCompanion.insert(
            id: id,
            worldId: worldId,
            regionId: regionId,
            name: name,
            x: x,
            y: y,
            z: z,
          ),
        );
  }

  Future<List<MetaverseZone>> listZones(String worldId) async {
    final query = database.select(database.metaverseZones)
      ..where((row) => row.worldId.equals(worldId));
    return query.get();
  }
}
