import 'dart:io';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/environment_type.dart';

class CreateEnvironmentService {
  CreateEnvironmentService({required this.database, required this.paths});

  final ProjectDatabase database;
  final ProjectPaths paths;

  Future<String> create({
    required String projectId,
    required String name,
    required EnvironmentType type,
  }) async {
    final id = const Uuid().v4();
    final now = DateTime.now();
    final projectDirectory = await paths.project(projectId);
    final environmentDirectory = Directory(
      '${projectDirectory.path}${Platform.pathSeparator}assets${Platform.pathSeparator}environments${Platform.pathSeparator}$id',
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
                type: 'environment',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.environments)
            .insert(
              EnvironmentsCompanion.insert(
                assetId: id,
                projectId: projectId,
                name: name,
                environmentType: Value(type.value),
              ),
            );
        await database
            .into(database.environmentWeatherProfiles)
            .insert(
              EnvironmentWeatherProfilesCompanion.insert(
                id: const Uuid().v4(),
                environmentId: id,
                name: 'Default',
                weatherPreset: WeatherPreset.clear.value,
                isDefault: const Value(true),
              ),
            );
        await database
            .into(database.environmentLightingProfiles)
            .insert(
              EnvironmentLightingProfilesCompanion.insert(
                id: const Uuid().v4(),
                environmentId: id,
                name: 'Default',
                timePreset: TimeOfDayPreset.noon.value,
              ),
            );
        await database
            .into(database.environmentPhysicsProfiles)
            .insert(
              EnvironmentPhysicsProfilesCompanion.insert(environmentId: id),
            );
      });

      for (final folder in [
        'references/exterior',
        'references/interior',
        'references/materials',
        'references/lighting',
        'references/weather',
        'references/continuity',
        'generated',
        'thumbnails',
        'exports',
      ]) {
        await Directory(
          '${environmentDirectory.path}${Platform.pathSeparator}$folder',
        ).create(recursive: true);
      }
      return id;
    } catch (_) {
      if (await environmentDirectory.exists()) {
        await environmentDirectory.delete(recursive: true);
      }
      rethrow;
    }
  }
}
