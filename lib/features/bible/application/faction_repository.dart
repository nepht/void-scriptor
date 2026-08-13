import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../../../database/project/tables/factions.dart' as schema;
import '../../../database/project/tables/faction_units.dart';
import '../domain/faction.dart' as domain;

part 'faction_repository.g.dart';

@DriftAccessor(tables: [schema.Factions, FactionUnits])
class FactionRepository extends DatabaseAccessor<ProjectDatabase>
    with _$FactionRepositoryMixin {
  FactionRepository(super.database);

  Future<void> save(domain.FactionModel faction) =>
      into(factions).insertOnConflictUpdate(
        FactionsCompanion.insert(
          assetId: faction.assetId,
          projectId: faction.projectId,
          name: faction.name,
          description: Value(faction.description),
          ideology: Value(faction.ideology),
          status: Value(faction.status),
          headquarters: Value(faction.headquarters),
        ),
      );

  Future<domain.FactionModel?> get(String assetId) async {
    final row = await (select(
      factions,
    )..where((item) => item.assetId.equals(assetId))).getSingleOrNull();
    if (row == null) return null;
    return domain.FactionModel(
      assetId: row.assetId,
      projectId: row.projectId,
      name: row.name,
      description: row.description,
      ideology: row.ideology,
      status: row.status,
      headquarters: row.headquarters,
    );
  }

  Future<void> saveUnit(domain.FactionUnitModel unit) =>
      into(factionUnits).insertOnConflictUpdate(
        FactionUnitsCompanion.insert(
          id: unit.id,
          factionId: unit.factionId,
          parentUnitId: Value(unit.parentUnitId),
          name: unit.name,
          description: Value(unit.description),
        ),
      );

  Future<List<domain.FactionUnitModel>> unitsFor(String factionId) async {
    final rows =
        await (select(factionUnits)
              ..where((item) => item.factionId.equals(factionId))
              ..orderBy([(item) => OrderingTerm(expression: item.name)]))
            .get();
    return rows
        .map(
          (row) => domain.FactionUnitModel(
            id: row.id,
            factionId: row.factionId,
            parentUnitId: row.parentUnitId,
            name: row.name,
            description: row.description,
          ),
        )
        .toList(growable: false);
  }
}
