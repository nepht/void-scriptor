import 'dart:convert';

import '../../../database/project/project_database.dart';
import '../domain/ai_provider.dart';

/// Caches provider model catalogs (Step 28.10).
class ModelCatalogRepository {
  ModelCatalogRepository(this.database);

  final ProjectDatabase database;

  Future<void> cache({
    required String providerId,
    required List<AiModelInfo> models,
  }) async {
    final now = DateTime.now();
    await database.batch((batch) {
      batch.deleteWhere(
        database.aiModelCatalog,
        (row) => row.providerId.equals(providerId),
      );
      for (final model in models) {
        batch.insert(
          database.aiModelCatalog,
          AiModelCatalogCompanion.insert(
            providerId: providerId,
            modelId: model.id,
            capabilitiesJson: jsonEncode(
              model.capabilities.map((c) => c.name).toList(),
            ),
            cachedAt: now,
          ),
        );
      }
    });
  }

  Future<List<AiModelInfo>> getModels(String providerId) async {
    final rows =
        await (database.select(database.aiModelCatalog)
              ..where((row) => row.providerId.equals(providerId)))
            .get();
    return rows
        .map(
          (row) => AiModelInfo(
            id: row.modelId,
            displayName: row.modelId,
            capabilities:
                (jsonDecode(row.capabilitiesJson) as List)
                    .map((name) => AiCapability.values.byName(name as String))
                    .toSet(),
          ),
        )
        .toList(growable: false);
  }
}
