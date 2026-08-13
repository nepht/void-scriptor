import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../../../database/project/tables/worldbuilding_entities.dart' as schema;
import '../domain/power_system.dart' as power;
import '../domain/species.dart' as species_domain;
import '../domain/technology.dart' as technology;

part 'worldbuilding_repository.g.dart';

@DriftAccessor(
  tables: [
    schema.Species,
    schema.Technologies,
    schema.PowerSystems,
    schema.PowerAbilities,
  ],
)
class WorldbuildingRepository extends DatabaseAccessor<ProjectDatabase>
    with _$WorldbuildingRepositoryMixin {
  WorldbuildingRepository(super.database);

  Future<void> saveSpecies(species_domain.SpeciesModel item) =>
      into(species).insertOnConflictUpdate(
        SpeciesCompanion.insert(
          assetId: item.assetId,
          projectId: item.projectId,
          name: item.name,
          origin: Value(item.origin),
          description: Value(item.description),
          lifespan: Value(item.lifespan),
          traits: Value(item.traits),
        ),
      );

  Future<void> saveTechnology(technology.TechnologyModel item) =>
      into(technologies).insertOnConflictUpdate(
        TechnologiesCompanion.insert(
          assetId: item.assetId,
          projectId: item.projectId,
          name: item.name,
          category: Value(item.category),
          description: Value(item.description),
          creator: Value(item.creator),
          limitations: Value(item.limitations),
        ),
      );

  Future<void> savePowerSystem(power.PowerSystemModel item) =>
      into(powerSystems).insertOnConflictUpdate(
        PowerSystemsCompanion.insert(
          assetId: item.assetId,
          projectId: item.projectId,
          name: item.name,
          description: Value(item.description),
          source: Value(item.source),
          rules: Value(item.rules),
          limitations: Value(item.limitations),
          visualLanguage: Value(item.visualLanguage),
        ),
      );

  Future<void> saveAbility(power.PowerAbilityModel item) =>
      into(powerAbilities).insertOnConflictUpdate(
        PowerAbilitiesCompanion.insert(
          id: item.id,
          powerSystemId: item.powerSystemId,
          name: item.name,
          description: Value(item.description),
          limitations: Value(item.limitations),
          sortOrder: Value(item.sortOrder),
        ),
      );

  Future<species_domain.SpeciesModel?> getSpecies(String assetId) async {
    final row = await (select(
      species,
    )..where((item) => item.assetId.equals(assetId))).getSingleOrNull();
    if (row == null) return null;
    return species_domain.SpeciesModel(
      assetId: row.assetId,
      projectId: row.projectId,
      name: row.name,
      origin: row.origin,
      description: row.description,
      lifespan: row.lifespan,
      traits: row.traits,
    );
  }

  Future<power.PowerSystemModel?> getPowerSystem(String assetId) async {
    final row = await (select(
      powerSystems,
    )..where((item) => item.assetId.equals(assetId))).getSingleOrNull();
    if (row == null) return null;
    return power.PowerSystemModel(
      assetId: row.assetId,
      projectId: row.projectId,
      name: row.name,
      description: row.description,
      source: row.source,
      rules: row.rules,
      limitations: row.limitations,
      visualLanguage: row.visualLanguage,
    );
  }

  Future<List<power.PowerAbilityModel>> abilitiesFor(
    String powerSystemId,
  ) async {
    final rows =
        await (select(powerAbilities)
              ..where((item) => item.powerSystemId.equals(powerSystemId))
              ..orderBy([(item) => OrderingTerm(expression: item.sortOrder)]))
            .get();
    return rows
        .map(
          (row) => power.PowerAbilityModel(
            id: row.id,
            powerSystemId: row.powerSystemId,
            name: row.name,
            description: row.description,
            limitations: row.limitations,
            sortOrder: row.sortOrder,
          ),
        )
        .toList(growable: false);
  }
}
