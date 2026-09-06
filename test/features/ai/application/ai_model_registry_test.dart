import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/database/project/project_database.dart';
import 'package:void_scriptor/features/ai/application/ai_model_registry.dart';
import 'package:void_scriptor/features/ai/application/model_catalog_repository.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';

class _Provider with AiStreamingFallback implements AiProvider {
  _Provider({this.id = 'registry-provider', this.fail = false});

  final bool fail;
  @override
  final String id;
  @override
  String get displayName => 'Registry Provider';
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};
  @override
  Future<List<AiModelInfo>> listModels() async {
    if (fail) throw StateError('provider unavailable');
    return const [
      AiModelInfo(
        id: 'model-a',
        displayName: 'Model A',
        capabilities: {AiCapability.textGeneration},
      ),
    ];
  }

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(
        providerRequestId: 'request-a',
        outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'ok')],
      );
  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => target == PromptTarget.story;
}

void main() {
  late ProjectDatabase db;
  late AiModelRegistry registry;

  setUp(() {
    db = ProjectDatabase(NativeDatabase.memory());
    registry = AiModelRegistry(ModelCatalogRepository(db));
  });

  tearDown(() async => db.close());

  test('refresh caches models and returns the fresh catalog', () async {
    final models = await registry.refresh(_Provider());
    expect(models.single.id, 'model-a');
    expect((await registry.cached('registry-provider')).single.id, 'model-a');
  });

  test('refreshAll returns catalogs keyed by registered provider', () async {
    final second = _Provider(id: 'second-provider');
    final providers = AiProviderRegistry([_Provider(), second]);

    final catalogs = await registry.refreshAll(providers);

    expect(
      catalogs.keys,
      containsAll(['registry-provider', 'second-provider']),
    );
    expect(catalogs['registry-provider']!.single.id, 'model-a');
    expect(catalogs['second-provider']!.single.id, 'model-a');
  });

  test(
    'refresh falls back to cached models when provider is unavailable',
    () async {
      await registry.refresh(_Provider());
      final models = await registry.refresh(_Provider(fail: true));
      expect(models.single.id, 'model-a');
    },
  );
}
