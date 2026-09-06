import 'package:drift/drift.dart';

import '../../../database/project/project_database.dart';
import '../../../database/project/tables/creatures.dart';
import '../domain/creature_model.dart' as domain;

part 'creature_repository.g.dart';

@DriftAccessor(
  tables: [
    Creatures,
    CreaturePhysicalProfiles,
    CreatureAbilities,
    CreatureModes,
  ],
)
class CreatureRepository extends DatabaseAccessor<ProjectDatabase>
    with _$CreatureRepositoryMixin {
  CreatureRepository(super.db);

  Future<List<domain.CreatureModel>> listForProject(String projectId) async {
    final rows =
        await (select(creatures)
              ..where((item) => item.projectId.equals(projectId))
              ..orderBy([(item) => OrderingTerm.asc(item.name)]))
            .get();
    return [
      for (final row in rows)
        domain.CreatureModel(
          assetId: row.assetId,
          projectId: row.projectId,
          name: row.name,
          category: domain.CreatureCategory.values.firstWhere(
            (item) => item.name == row.category,
            orElse: () => domain.CreatureCategory.unknown,
          ),
          speciesId: row.speciesId,
          description: row.description,
          behavior: row.behavior,
          abilities: row.abilities,
          origin: row.origin,
        ),
    ];
  }

  Future<domain.CreatureModel?> getCreature(String id) async {
    final row = await (select(
      creatures,
    )..where((item) => item.assetId.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : domain.CreatureModel(
            assetId: row.assetId,
            projectId: row.projectId,
            name: row.name,
            category: domain.CreatureCategory.values.firstWhere(
              (item) => item.name == row.category,
              orElse: () => domain.CreatureCategory.unknown,
            ),
            speciesId: row.speciesId,
            description: row.description,
            behavior: row.behavior,
            abilities: row.abilities,
            origin: row.origin,
          );
  }

  Future<void> savePhysicalProfile(domain.CreaturePhysicalProfile profile) =>
      into(creaturePhysicalProfiles).insertOnConflictUpdate(
        CreaturePhysicalProfilesCompanion.insert(
          creatureId: profile.creatureId,
          heightCm: Value(profile.heightCm),
          lengthCm: Value(profile.lengthCm),
          weightKg: Value(profile.weightKg),
          bodyStructure: Value(profile.bodyStructure),
          skinMaterial: Value(profile.skinMaterial),
          eyeDescription: Value(profile.eyeDescription),
          distinguishingFeatures: Value(profile.distinguishingFeatures),
        ),
      );

  Future<domain.CreaturePhysicalProfile?> getPhysicalProfile(String id) async {
    final row = await (select(
      creaturePhysicalProfiles,
    )..where((item) => item.creatureId.equals(id))).getSingleOrNull();
    return row == null
        ? null
        : domain.CreaturePhysicalProfile(
            creatureId: row.creatureId,
            heightCm: row.heightCm,
            lengthCm: row.lengthCm,
            weightKg: row.weightKg,
            bodyStructure: row.bodyStructure,
            skinMaterial: row.skinMaterial,
            eyeDescription: row.eyeDescription,
            distinguishingFeatures: row.distinguishingFeatures,
          );
  }

  Future<void> saveAbility(domain.CreatureAbilityModel ability) =>
      into(creatureAbilities).insertOnConflictUpdate(
        CreatureAbilitiesCompanion.insert(
          id: ability.id,
          creatureId: ability.creatureId,
          name: ability.name,
          description: Value(ability.description),
          powerSystemId: Value(ability.powerSystemId),
          sortOrder: Value(ability.sortOrder),
        ),
      );

  Future<List<domain.CreatureAbilityModel>> abilitiesFor(String id) async {
    final rows =
        await (select(creatureAbilities)
              ..where((item) => item.creatureId.equals(id))
              ..orderBy([(item) => OrderingTerm.asc(item.sortOrder)]))
            .get();
    return [
      for (final row in rows)
        domain.CreatureAbilityModel(
          id: row.id,
          creatureId: row.creatureId,
          name: row.name,
          description: row.description,
          powerSystemId: row.powerSystemId,
          sortOrder: row.sortOrder,
        ),
    ];
  }

  Future<void> saveMode(domain.CreatureModeModel mode) =>
      into(creatureModes).insertOnConflictUpdate(
        CreatureModesCompanion.insert(
          id: mode.id,
          creatureId: mode.creatureId,
          name: mode.name,
          description: Value(mode.description),
          referenceSetId: Value(mode.referenceSetId),
          defaultMode: Value(mode.defaultMode),
        ),
      );

  Future<List<domain.CreatureModeModel>> modesFor(String id) async {
    final rows =
        await (select(creatureModes)
              ..where((item) => item.creatureId.equals(id))
              ..orderBy([(item) => OrderingTerm.asc(item.rowId)]))
            .get();
    return [
      for (final row in rows)
        domain.CreatureModeModel(
          id: row.id,
          creatureId: row.creatureId,
          name: row.name,
          description: row.description,
          referenceSetId: row.referenceSetId,
          defaultMode: row.defaultMode,
        ),
    ];
  }
}
