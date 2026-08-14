import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart' as db;
import '../domain/vfx_model.dart' as domain;

class CreateVfxService {
  CreateVfxService(this.database, {ProjectPaths? paths})
    : paths = paths ?? ProjectPaths();
  final db.ProjectDatabase database;
  final ProjectPaths paths;
  Future<String> create({
    required String projectId,
    required String name,
    required domain.VfxCategory category,
    String description = '',
    String visualBehavior = '',
    String colorPalette = '',
    domain.VfxBehaviorProfile behavior = const domain.VfxBehaviorProfile(),
    List<domain.VfxStateModel> states = const [],
  }) async {
    final id = const Uuid().v4(), now = DateTime.now().toUtc();
    await database.transaction(() async {
      await database
          .into(database.assets)
          .insert(
            db.AssetsCompanion.insert(
              id: id,
              projectId: projectId,
              name: name,
              type: 'vfx',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.vfxAssets)
          .insert(
            db.VfxAssetsCompanion.insert(
              assetId: id,
              projectId: projectId,
              name: name,
              category: category.name,
              description: Value(description),
              visualBehavior: Value(visualBehavior),
              colorPalette: Value(colorPalette),
            ),
          );
      await database
          .into(database.vfxBehaviorProfiles)
          .insert(
            db.VfxBehaviorProfilesCompanion.insert(
              vfxId: id,
              originBehavior: Value(behavior.originBehavior),
              movementBehavior: Value(behavior.movementBehavior),
              dissipationBehavior: Value(behavior.dissipationBehavior),
              environmentalInteraction: Value(
                behavior.environmentalInteraction,
              ),
              defaultDurationSeconds: Value(behavior.defaultDurationSeconds),
              emitsLight: Value(behavior.emitsLight),
            ),
          );
      for (final state in states) {
        await database
            .into(database.vfxStates)
            .insert(
              db.VfxStatesCompanion.insert(
                id: state.id,
                vfxId: id,
                name: state.name,
                description: Value(state.description),
                referenceSetId: Value(state.referenceSetId),
                sortOrder: Value(state.sortOrder),
              ),
            );
      }
    });
    final dir = Directory(
      '${(await paths.project(projectId)).path}/assets/$id',
    );
    await dir.create(recursive: true);
    return id;
  }
}
