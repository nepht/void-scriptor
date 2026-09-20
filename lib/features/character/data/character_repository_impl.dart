import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../../../database/project/daos/character_dao.dart';
import '../../../database/project/project_database.dart'
    hide
        CharacterIdentityProfile,
        CharacterReference,
        CharacterCanonicalScope,
        CharacterUniverseTimelineOverride,
        CharacterNovelState;
import '../../../core/persistence/project_paths.dart';
import '../../workspaces/application/narrative_assignment_repository.dart';
import '../application/create_character_service.dart';
import '../domain/character_model.dart';
import '../domain/character_repository.dart';
import '../domain/character_identity_profile.dart';
import '../domain/character_reference.dart';
import '../domain/character_scope_layers.dart';

class CharacterRepositoryImpl implements CharacterRepository {
  CharacterRepositoryImpl({
    required this.database,
    required this.projectId,
    required this.paths,
  });

  final ProjectDatabase database;
  final String projectId;
  final ProjectPaths paths;

  CharacterDao get _dao => database.characterDao;

  @override
  Future<List<CharacterModel>> getCharacters() async =>
      (await _dao.getAllCharacters(projectId)).map(_fromRow).toList();

  @override
  Future<List<CharacterModel>> searchCharacters(String query) async {
    final normalized = query.trim().toLowerCase();
    final characters = await getCharacters();
    if (normalized.isEmpty) return characters;
    return characters
        .where(
          (character) =>
              character.displayName.toLowerCase().contains(normalized) ||
              character.alias.toLowerCase().contains(normalized),
        )
        .toList(growable: false);
  }

  @override
  Future<CharacterModel?> getCharacter(String id) async {
    final row = await _dao.getCharacter(id);
    return row == null ? null : _fromRow(row);
  }

  @override
  Future<CharacterModel> createCharacter({required String name}) async {
    final id = await CreateCharacterService(
      database: database,
      paths: paths,
    ).create(projectId: projectId, name: name);
    return (await getCharacter(id))!;
  }

  @override
  Future<void> updateCharacter(CharacterModel character) async {
    await database.transaction(() async {
      await database
          .update(database.characters)
          .replace(
            CharactersCompanion(
              assetId: Value(character.assetId),
              projectId: Value(character.projectId),
              displayName: Value(character.displayName),
              alias: Value(character.alias),
              biography: Value(character.biography),
              personality: Value(character.personality),
              gender: Value(character.gender),
              age: Value(character.age),
              heightCm: Value(character.heightCm),
              hair: Value(character.hair),
              eyes: Value(character.eyes),
              skin: Value(character.skin),
              voice: Value(character.voice),
            ),
          );
      await (database.update(
        database.assets,
      )..where((row) => row.id.equals(character.assetId))).write(
        AssetsCompanion(
          name: Value(character.displayName),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }

  @override
  Future<void> deleteCharacter(String id) async {
    await database.transaction(() async {
      await _dao.removeCharacterReferences(id);
      await _dao.removeCharacterScopeRows(id);
      await database.characterModeDao.removeCharacterModes(id);
      await database.assetDao.removeAssetData(id);
      await (database.delete(
        database.characterIdentityProfiles,
      )..where((row) => row.characterId.equals(id))).go();
      await (database.delete(
        database.characters,
      )..where((row) => row.assetId.equals(id))).go();
      await (database.delete(
        database.assets,
      )..where((row) => row.id.equals(id))).go();
      // bug-hunt run157 BUG-02: clear narrative rows so a deleted character
      // never leaves orphan assignments/support rows. Runs inside this
      // transaction, so the two deletes are atomic with the deletion.
      await NarrativeAssignmentRepository(
        database: database,
        projectId: projectId,
      ).deleteForCharacter(id);
    });
    final project = await paths.project(projectId);
    final directory = Directory(
      p.join(project.path, 'assets', 'characters', id),
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  @override
  Future<CharacterIdentityProfile?> getIdentity(String characterId) async {
    final row = await _dao.getIdentity(characterId);
    return row == null
        ? null
        : CharacterIdentityProfile(
            characterId: row.characterId,
            faceLock: row.faceLock,
            hairLock: row.hairLock,
            bodyLock: row.bodyLock,
            colorLock: row.colorLock,
            outfitLock: row.outfitLock,
            weaponLock: row.weaponLock,
            accessoryLock: row.accessoryLock,
            notes: row.notes,
          );
  }

  @override
  Future<void> updateIdentity(CharacterIdentityProfile profile) =>
      _dao.updateIdentity(
        CharacterIdentityProfilesCompanion.insert(
          characterId: profile.characterId,
          faceLock: Value(profile.faceLock),
          hairLock: Value(profile.hairLock),
          bodyLock: Value(profile.bodyLock),
          colorLock: Value(profile.colorLock),
          outfitLock: Value(profile.outfitLock),
          weaponLock: Value(profile.weaponLock),
          accessoryLock: Value(profile.accessoryLock),
          notes: Value(profile.notes),
        ),
      );

  @override
  Future<List<CharacterReference>> getReferences(String characterId) async =>
      (await _dao.getReferences(characterId))
          .map(
            (row) => CharacterReference(
              id: row.id,
              characterId: row.characterId,
              type: row.type,
              filePath: row.filePath,
              priority: row.priority,
              primaryReference: row.primaryReference,
            ),
          )
          .toList(growable: false);

  @override
  Future<void> addReference(CharacterReference reference) => _dao.addReference(
    CharacterReferencesCompanion.insert(
      id: reference.id,
      characterId: reference.characterId,
      type: reference.type,
      filePath: reference.filePath,
      priority: Value(reference.priority),
      primaryReference: Value(reference.primaryReference),
    ),
  );

  @override
  Future<void> removeReference(String referenceId) =>
      _dao.removeReference(referenceId);

  @override
  Future<List<String>> getTags(String assetId) =>
      database.assetDao.getTags(assetId);

  @override
  Future<void> replaceTags(String assetId, List<String> tags) =>
      database.assetDao.replaceTags(assetId, tags);

  @override
  Future<void> addRelation({
    required String id,
    required String sourceAssetId,
    required String targetAssetId,
    required String relationType,
  }) => database.assetDao.addRelation(
    id: id,
    sourceAssetId: sourceAssetId,
    targetAssetId: targetAssetId,
    relationType: relationType,
  );

  CharacterModel _fromRow(Character row) => CharacterModel(
    assetId: row.assetId,
    projectId: row.projectId,
    displayName: row.displayName,
    alias: row.alias,
    biography: row.biography,
    personality: row.personality,
    gender: row.gender,
    age: row.age,
    heightCm: row.heightCm,
    hair: row.hair,
    eyes: row.eyes,
    skin: row.skin,
    voice: row.voice,
  );

  @override
  Future<Map<CharacterScopeLayer, CharacterScopeState>> getScopeStates(
    String characterId,
  ) async {
    final canonicalRow = await _dao.getCanonicalScope(characterId);
    final universeRow = await _dao.getUniverseTimelineScope(characterId);
    final novelRow = await _dao.getNovelScope(characterId);
    return {
      CharacterScopeLayer.canonical: CharacterScopeState(
        identity: canonicalRow?.identity,
        baseVoice: canonicalRow?.baseVoice,
        baseVisualProfile: canonicalRow?.baseVisualProfile,
        baseRelationReferences: canonicalRow?.baseRelationReferences,
      ),
      CharacterScopeLayer.universeTimeline: CharacterScopeState(
        alternateHistory: universeRow?.alternateHistory,
        alternateRelationships: universeRow?.alternateRelationships,
        eraSpecificFacts: universeRow?.eraSpecificFacts,
      ),
      CharacterScopeLayer.novelSpecific: CharacterScopeState(
        role: novelRow?.role,
        arc: novelRow?.arc,
        currentLocation: novelRow?.currentLocation,
        currentAge: novelRow?.currentAge,
        currentStatus: novelRow?.currentStatus,
        scenePov: novelRow?.scenePov,
        novelRelationState: novelRow?.novelRelationState,
      ),
    };
  }

  @override
  Future<void> updateScopeState(
    String characterId,
    CharacterScopeLayer layer,
    CharacterScopeState state,
  ) async {
    switch (layer) {
      case CharacterScopeLayer.canonical:
        await _dao.upsertCanonicalScope(
          CharacterCanonicalScopesCompanion.insert(
            characterId: characterId,
            identity: Value(state.identity),
            baseVoice: Value(state.baseVoice),
            baseVisualProfile: Value(state.baseVisualProfile),
            baseRelationReferences: Value(state.baseRelationReferences),
          ),
        );
      case CharacterScopeLayer.universeTimeline:
        await _dao.upsertUniverseTimelineScope(
          CharacterUniverseTimelineOverridesCompanion.insert(
            characterId: characterId,
            alternateHistory: Value(state.alternateHistory),
            alternateRelationships: Value(state.alternateRelationships),
            eraSpecificFacts: Value(state.eraSpecificFacts),
          ),
        );
      case CharacterScopeLayer.novelSpecific:
        await _dao.upsertNovelScope(
          CharacterNovelStatesCompanion.insert(
            characterId: characterId,
            role: Value(state.role),
            arc: Value(state.arc),
            currentLocation: Value(state.currentLocation),
            currentAge: Value(state.currentAge),
            currentStatus: Value(state.currentStatus),
            scenePov: Value(state.scenePov),
            novelRelationState: Value(state.novelRelationState),
          ),
        );
    }
  }
}
