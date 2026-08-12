import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';

class CreateWeaponService {
  CreateWeaponService({required this.database, required this.paths});

  final ProjectDatabase database;
  final ProjectPaths paths;

  Future<String> create({
    required String projectId,
    required String name,
    required String weaponType,
  }) async {
    final weaponId = const Uuid().v4();
    final now = DateTime.now();
    final projectDirectory = await paths.project(projectId);
    final weaponDirectory = Directory(
      '${projectDirectory.path}${Platform.pathSeparator}assets${Platform.pathSeparator}weapons${Platform.pathSeparator}$weaponId',
    );

    try {
      await database.transaction(() async {
        await database
            .into(database.assets)
            .insert(
              AssetsCompanion.insert(
                id: weaponId,
                projectId: projectId,
                name: name,
                type: 'weapon',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.weapons)
            .insert(
              WeaponsCompanion.insert(
                assetId: weaponId,
                projectId: projectId,
                name: name,
                weaponType: Value(weaponType),
              ),
            );
        await database
            .into(database.weaponVariants)
            .insert(
              WeaponVariantsCompanion.insert(
                id: const Uuid().v4(),
                weaponId: weaponId,
                name: 'Normal',
                isDefault: const Value(true),
              ),
            );
        await database
            .into(database.weaponPreservationProfiles)
            .insert(
              WeaponPreservationProfilesCompanion.insert(weaponId: weaponId),
            );
      });

      for (final folder in [
        'references/orthographic',
        'references/closeup',
        'references/material',
        'references/effects',
        'generated',
        'thumbnails',
        'exports',
      ]) {
        await Directory(
          '${weaponDirectory.path}${Platform.pathSeparator}$folder',
        ).create(recursive: true);
      }
      return weaponId;
    } catch (_) {
      if (await weaponDirectory.exists()) {
        await weaponDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }
}
