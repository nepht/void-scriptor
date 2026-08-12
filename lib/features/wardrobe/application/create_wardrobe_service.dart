import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';

class CreateWardrobeService {
  CreateWardrobeService({required this.database, required this.paths});

  final ProjectDatabase database;
  final ProjectPaths paths;

  Future<String> create({
    required String projectId,
    required String name,
  }) async {
    final wardrobeId = const Uuid().v4();
    final now = DateTime.now();
    final projectDirectory = await paths.project(projectId);
    final wardrobeDirectory = Directory(
      '${projectDirectory.path}${Platform.pathSeparator}assets${Platform.pathSeparator}wardrobe${Platform.pathSeparator}$wardrobeId',
    );

    try {
      await database.transaction(() async {
        await database
            .into(database.assets)
            .insert(
              AssetsCompanion.insert(
                id: wardrobeId,
                projectId: projectId,
                name: name,
                type: 'wardrobe',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.wardrobes)
            .insert(
              WardrobesCompanion.insert(
                assetId: wardrobeId,
                projectId: projectId,
                name: name,
              ),
            );
        await database
            .into(database.wardrobeVariants)
            .insert(
              WardrobeVariantsCompanion.insert(
                id: const Uuid().v4(),
                wardrobeId: wardrobeId,
                name: 'Normal',
                isDefault: const Value(true),
              ),
            );
      });
      for (final folder in [
        'references',
        'materials',
        'thumbnails',
        'generated',
        'exports',
      ]) {
        await Directory(
          '${wardrobeDirectory.path}${Platform.pathSeparator}$folder',
        ).create(recursive: true);
      }
      return wardrobeId;
    } catch (_) {
      if (await wardrobeDirectory.exists()) {
        await wardrobeDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }
}
