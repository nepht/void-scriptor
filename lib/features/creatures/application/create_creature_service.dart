import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/creature_model.dart';

class CreateCreatureService {
  CreateCreatureService({required this.database, required this.paths});

  final ProjectDatabase database;
  final ProjectPaths paths;

  Future<String> create({
    required String projectId,
    required String name,
    required CreatureCategory category,
    String? speciesId,
    String description = '',
    String behavior = '',
    String abilities = '',
    String origin = '',
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final projectDirectory = await paths.project(projectId);
    final directory = Directory(
      '${projectDirectory.path}${Platform.pathSeparator}assets${Platform.pathSeparator}creatures${Platform.pathSeparator}$id',
    );
    try {
      await database.transaction(() async {
        await database
            .into(database.assets)
            .insert(
              AssetsCompanion.insert(
                id: id,
                projectId: projectId,
                name: name,
                type: 'creature',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.creatures)
            .insert(
              CreaturesCompanion.insert(
                assetId: id,
                projectId: projectId,
                name: name,
                category: category.name,
                speciesId: Value(speciesId),
                description: Value(description),
                behavior: Value(behavior),
                abilities: Value(abilities),
                origin: Value(origin),
              ),
            );
        await database
            .into(database.creaturePhysicalProfiles)
            .insert(CreaturePhysicalProfilesCompanion.insert(creatureId: id));
      });
      for (final folder in [
        'references/detail-sheet',
        'references/modes',
        'generated',
        'thumbnails',
        'exports',
      ]) {
        await Directory(
          '${directory.path}${Platform.pathSeparator}$folder',
        ).create(recursive: true);
      }
      return id;
    } catch (_) {
      if (await directory.exists()) await directory.delete(recursive: true);
      rethrow;
    }
  }
}
