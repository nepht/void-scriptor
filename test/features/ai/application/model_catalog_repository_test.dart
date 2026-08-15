import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/model_catalog_repository.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

void main() {
  late ProjectDatabase db;
  late ModelCatalogRepository repository;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    repository = ModelCatalogRepository(db);
  });

  tearDown(() async => db.close());

  test('caches and reads model catalog', () async {
    await repository.cache(
      providerId: 'openai',
      models: const [
        AiModelInfo(
          id: 'gpt-4',
          displayName: 'GPT-4',
          capabilities: {AiCapability.textGeneration},
        ),
      ],
    );
    final models = await repository.getModels('openai');
    expect(models, hasLength(1));
    expect(models.single.id, 'gpt-4');
    expect(models.single.capabilities, {AiCapability.textGeneration});
  });

  test('returns empty list for unknown provider', () async {
    expect(await repository.getModels('unknown'), isEmpty);
  });
}
