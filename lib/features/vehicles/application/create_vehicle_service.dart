import 'dart:io';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/persistence/project_paths.dart';
import '../../../database/project/project_database.dart';
import '../domain/vehicle_model.dart';

class CreateVehicleService {
  CreateVehicleService({required this.database, required this.paths});
  final ProjectDatabase database;
  final ProjectPaths paths;
  Future<String> create({
    required String projectId,
    required String name,
    required VehicleCategory category,
    String description = '',
    String manufacturer = '',
    String role = '',
  }) async {
    final id = const Uuid().v4(), now = DateTime.now();
    final root = await paths.project(projectId);
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}assets${Platform.pathSeparator}vehicles${Platform.pathSeparator}$id',
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
                type: 'vehicle',
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database
            .into(database.vehicles)
            .insert(
              VehiclesCompanion.insert(
                assetId: id,
                projectId: projectId,
                name: name,
                category: category.name,
                description: Value(description),
                manufacturer: Value(manufacturer),
                role: Value(role),
              ),
            );
        await database
            .into(database.vehicleSpecifications)
            .insert(VehicleSpecificationsCompanion.insert(vehicleId: id));
      });
      for (final f in [
        'references/technical',
        'references/interior',
        'references/variants',
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
