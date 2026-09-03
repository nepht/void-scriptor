import '../domain/ai_provider.dart';
import 'model_catalog_repository.dart';

class AiModelRegistry {
  AiModelRegistry(this.catalog);

  final ModelCatalogRepository catalog;

  Future<List<AiModelInfo>> refresh(AiProvider provider) async {
    try {
      final models = await provider.listModels();
      await catalog.cache(providerId: provider.id, models: models);
      return models;
    } catch (_) {
      final cachedModels = await catalog.getModels(provider.id);
      if (cachedModels.isNotEmpty) return cachedModels;
      rethrow;
    }
  }

  Future<Map<String, List<AiModelInfo>>> refreshAll(
    AiProviderRegistry providers,
  ) async {
    final catalogs = <String, List<AiModelInfo>>{};
    for (final provider in providers.all) {
      catalogs[provider.id] = await refresh(provider);
    }
    return Map.unmodifiable(catalogs);
  }

  Future<List<AiModelInfo>> cached(String providerId) =>
      catalog.getModels(providerId);
}
