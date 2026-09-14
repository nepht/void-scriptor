import 'dart:io';

import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/wardrobe_model.dart';
import '../domain/wardrobe_repository.dart';
import '../domain/wardrobe_workspace_data.dart';

class WardrobeRepositoryImpl implements WardrobeRepository {
  WardrobeRepositoryImpl({
    required this.database,
    required this.projectId,
    ProjectPaths? paths,
  }) : paths = paths ?? ProjectPaths();

  final ProjectDatabase database;
  final String projectId;
  final ProjectPaths paths;

  @override
  Future<List<WardrobeModel>> getWardrobes() async =>
      (await database.wardrobeDao.getWardrobes(projectId)).map(_map).toList();

  @override
  Future<WardrobeModel?> getWardrobe(String assetId) async {
    final row = await database.wardrobeDao.getWardrobe(assetId);
    return row == null ? null : _map(row);
  }

  @override
  Future<WardrobeWorkspaceData> getWorkspaceData(String assetId) async {
    final components = await database.wardrobeDao.getComponents(assetId);
    final colors = await database.wardrobeDao.getColors(assetId);
    final variants = await database.wardrobeDao.getVariants(assetId);
    final references = await database.wardrobeDao.getReferences(assetId);
    return WardrobeWorkspaceData(
      components: [
        for (final component in components)
          WardrobeComponentInfo(
            name: component.name,
            componentType: component.componentType,
            material: component.material,
            fabric: component.fabric,
          ),
      ],
      colors: [
        for (final color in colors)
          WardrobeColorInfo(name: color.name, hexValue: color.hexValue),
      ],
      variants: [
        for (final variant in variants)
          WardrobeVariantInfo(name: variant.name, isDefault: variant.isDefault),
      ],
      references: [
        for (final reference in references)
          WardrobeReferenceInfo(
            referenceType: reference.referenceType,
            filePath: reference.filePath,
          ),
      ],
    );
  }

  @override
  Future<void> deleteWardrobe(String assetId) async {
    await database.transaction(() async {
      await database.assetDao.removeAssetData(assetId);
      await (database.delete(
        database.wardrobeComponents,
      )..where((row) => row.wardrobeId.equals(assetId))).go();
      await (database.delete(
        database.wardrobeColors,
      )..where((row) => row.wardrobeId.equals(assetId))).go();
      await (database.delete(
        database.wardrobeVariants,
      )..where((row) => row.wardrobeId.equals(assetId))).go();
      await (database.delete(
        database.wardrobeReferences,
      )..where((row) => row.wardrobeId.equals(assetId))).go();
      await (database.delete(
        database.wardrobes,
      )..where((row) => row.assetId.equals(assetId))).go();
      await (database.delete(
        database.assets,
      )..where((row) => row.id.equals(assetId))).go();
    });
    final project = await paths.project(projectId);
    final directory = Directory(
      '${project.path}${Platform.pathSeparator}assets${Platform.pathSeparator}wardrobe${Platform.pathSeparator}$assetId',
    );
    if (await directory.exists()) await directory.delete(recursive: true);
  }

  WardrobeModel _map(Wardrobe row) => WardrobeModel(
    assetId: row.assetId,
    projectId: row.projectId,
    name: row.name,
    category: row.category,
    description: row.description,
    primaryMaterial: row.primaryMaterial,
    fabric: row.fabric,
    fit: row.fit,
    style: row.style,
    notes: row.notes,
  );
}
