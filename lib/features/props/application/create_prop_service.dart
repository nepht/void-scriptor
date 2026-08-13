import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/prop_model.dart';

class CreatePropService {
  CreatePropService({required this.database, required this.paths});
  final ProjectDatabase database;
  final ProjectPaths paths;
  Future<String> create({
    required String projectId,
    required String name,
    required PropCategory category,
    String description = '',
    String function = '',
    bool storyCritical = false,
  }) async {
    final id = const Uuid().v4(), now = DateTime.now();
    final root = await paths.project(projectId);
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}props${Platform.pathSeparator}$id',
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
                type: 'prop',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.props)
            .insert(
              PropsCompanion.insert(
                assetId: id,
                projectId: projectId,
                name: name,
                category: category.name,
                description: Value(description),
                function: Value(function),
                storyCritical: Value(storyCritical),
              ),
            );
        await database
            .into(database.propSpecifications)
            .insert(PropSpecificationsCompanion.insert(propId: id));
      });
      for (final f in [
        'references/detail-sheet',
        'references/states',
        'generated',
        'thumbnails',
        'exports',
      ]) {
        await Directory(
          '${dir.path}${Platform.pathSeparator}$f',
        ).create(recursive: true);
      }
      return id;
    } catch (_) {
      if (await dir.exists()) await dir.delete(recursive: true);
      rethrow;
    }
  }
}
