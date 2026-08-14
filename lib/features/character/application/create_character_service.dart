import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';

class CreateCharacterService {
  CreateCharacterService({required this.database, required this.paths});

  final ProjectDatabase database;
  final ProjectPaths paths;

  Future<String> create({
    required String projectId,
    required String name,
  }) async {
    final characterId = const Uuid().v4();
    final now = DateTime.now();
    final directory = await paths.project(projectId);
    final characterDirectory = Directory(
      p.join(directory.path, 'assets', 'characters', characterId),
    );

    try {
      await database.transaction(() async {
        await database
            .into(database.assets)
            .insert(
              AssetsCompanion.insert(
                id: characterId,
                projectId: projectId,
                name: name,
                type: 'character',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.characters)
            .insert(
              CharactersCompanion.insert(
                assetId: characterId,
                projectId: projectId,
                displayName: name,
              ),
            );
        await database
            .into(database.characterIdentityProfiles)
            .insert(
              CharacterIdentityProfilesCompanion.insert(
                characterId: characterId,
              ),
            );
        final modeId = const Uuid().v4();
        await database
            .into(database.characterModes)
            .insert(
              CharacterModesCompanion.insert(
                id: modeId,
                projectId: projectId,
                characterId: characterId,
                name: 'Base Mode',
                isDefault: const Value(true),
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.characterModeIdentityOverrides)
            .insert(
              CharacterModeIdentityOverridesCompanion.insert(modeId: modeId),
            );
      });
      await _createCharacterFolders(characterDirectory);
      return characterId;
    } catch (_) {
      if (await characterDirectory.exists()) {
        await characterDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }

  Future<void> _createCharacterFolders(Directory directory) async {
    for (final child in [
      'references/face',
      'references/body',
      'references/hair',
      'references/poses',
      'references/expressions',
      'generated',
      'thumbnails',
      'exports',
    ]) {
      await Directory(p.join(directory.path, child)).create(recursive: true);
    }
  }
}
