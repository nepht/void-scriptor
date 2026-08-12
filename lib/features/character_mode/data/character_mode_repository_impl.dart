import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../database/project/project_database.dart' as db;
import '../domain/character_mode.dart' as domain;

abstract interface class CharacterModeRepository {
  Future<List<domain.CharacterMode>> getModes(String characterId);
  Future<domain.CharacterMode?> getMode(String modeId);
  Future<String> createMode({
    required String projectId,
    required String characterId,
    required String name,
    bool isDefault,
    String description,
  });
  Future<String> cloneMode({
    required String sourceModeId,
    required String name,
  });
}

class CharacterModeRepositoryImpl implements CharacterModeRepository {
  CharacterModeRepositoryImpl(this.database);

  final db.ProjectDatabase database;

  domain.CharacterMode _mapMode(db.CharacterMode row) => domain.CharacterMode(
    id: row.id,
    projectId: row.projectId,
    characterId: row.characterId,
    name: row.name,
    description: row.description,
    isDefault: row.isDefault,
    thumbnailPath: row.thumbnailPath,
  );

  @override
  Future<List<domain.CharacterMode>> getModes(String characterId) async =>
      (await database.characterModeDao.getModes(
        characterId,
      )).map(_mapMode).toList();

  @override
  Future<domain.CharacterMode?> getMode(String modeId) async {
    final row = await database.characterModeDao.getMode(modeId);
    return row == null ? null : _mapMode(row);
  }

  @override
  Future<String> createMode({
    required String projectId,
    required String characterId,
    required String name,
    bool isDefault = false,
    String description = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    await database.transaction(() async {
      if (isDefault) {
        await (database.update(database.characterModes)
              ..where((row) => row.characterId.equals(characterId)))
            .write(const db.CharacterModesCompanion(isDefault: Value(false)));
      }
      await database.characterModeDao.insertMode(
        db.CharacterModesCompanion.insert(
          id: id,
          projectId: projectId,
          characterId: characterId,
          name: name,
          description: Value(description),
          isDefault: Value(isDefault),
          createdAt: now,
          updatedAt: now,
        ),
      );
      await database.characterModeDao.upsertIdentityOverride(
        db.CharacterModeIdentityOverridesCompanion.insert(modeId: id),
      );
    });
    return id;
  }

  @override
  Future<String> cloneMode({
    required String sourceModeId,
    required String name,
  }) async {
    final source = await database.characterModeDao.getMode(sourceModeId);
    if (source == null) throw ArgumentError('Source mode not found');
    final newId = await createMode(
      projectId: source.projectId,
      characterId: source.characterId,
      name: name,
      description: source.description,
    );
    final entries = await database.characterModeDao.getLoadout(sourceModeId);
    final override = await database.characterModeDao.getIdentityOverride(
      sourceModeId,
    );
    final references = await database.characterModeDao.getReferences(
      sourceModeId,
    );
    await database.transaction(() async {
      for (final entry in entries) {
        await database.characterModeDao.insertLoadoutEntry(
          db.CharacterLoadoutEntriesCompanion.insert(
            id: const Uuid().v4(),
            modeId: newId,
            assetId: entry.assetId,
            slot: entry.slot,
            sortOrder: Value(entry.sortOrder),
            enabled: Value(entry.enabled),
          ),
        );
      }
      if (override != null) {
        await database.characterModeDao.upsertIdentityOverride(
          db.CharacterModeIdentityOverridesCompanion(
            modeId: Value(newId),
            faceLock: Value(override.faceLock),
            hairLock: Value(override.hairLock),
            bodyLock: Value(override.bodyLock),
            colorLock: Value(override.colorLock),
            outfitLock: Value(override.outfitLock),
            weaponLock: Value(override.weaponLock),
          ),
        );
      }
      for (final reference in references) {
        await database
            .into(database.characterModeReferences)
            .insert(
              db.CharacterModeReferencesCompanion.insert(
                id: const Uuid().v4(),
                modeId: newId,
                referenceType: reference.referenceType,
                filePath: reference.filePath,
                priority: Value(reference.priority),
                primaryReference: Value(reference.primaryReference),
              ),
            );
      }
    });
    return newId;
  }
}
