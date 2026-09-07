import '../../../database/project/project_database.dart';
import '../../assets/domain/asset_relation_type.dart';

/// One readable row of the project-level character relationship map
/// (Step 145.27 Core Worldbuilding Reduction).
class CharacterRelationMapEntry {
  const CharacterRelationMapEntry({
    required this.relationId,
    required this.sourceAssetId,
    required this.sourceName,
    required this.targetAssetId,
    required this.targetName,
    required this.typeLabel,
  });

  final String relationId;
  final String sourceAssetId;
  final String sourceName;
  final String targetAssetId;
  final String targetName;
  final String typeLabel;
}

/// Step 145.27 Relationship Map contract (service layer): resolves every
/// project relation whose endpoints are characters into display rows with
/// real names. Non-character endpoints keep their asset id as name so the
/// map stays honest instead of silently dropping rows.
class CharacterRelationMapService {
  const CharacterRelationMapService();

  Future<List<CharacterRelationMapEntry>> mapForProject(
    ProjectDatabase database, {
    required String projectId,
  }) async {
    final relations = await database.relationDao.getProjectRelations(projectId);
    if (relations.isEmpty) return const [];

    final characters = await database.characterDao.getAllCharacters(projectId);
    final characterNames = {
      for (final character in characters)
        character.assetId: character.displayName,
    };

    final entries = <CharacterRelationMapEntry>[];
    for (final relation in relations) {
      final sourceIsCharacter = characterNames.containsKey(
        relation.sourceAssetId,
      );
      final targetIsCharacter = characterNames.containsKey(
        relation.targetAssetId,
      );
      if (!sourceIsCharacter && !targetIsCharacter) continue;
      final type = AssetRelationType.values.firstWhere(
        (candidate) => candidate.value == relation.relationType,
        orElse: () => AssetRelationType.relatedTo,
      );
      entries.add(
        CharacterRelationMapEntry(
          relationId: relation.id,
          sourceAssetId: relation.sourceAssetId,
          sourceName:
              characterNames[relation.sourceAssetId] ?? relation.sourceAssetId,
          targetAssetId: relation.targetAssetId,
          targetName:
              characterNames[relation.targetAssetId] ?? relation.targetAssetId,
          typeLabel: type.value,
        ),
      );
    }
    return entries;
  }
}
