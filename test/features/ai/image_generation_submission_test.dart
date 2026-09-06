import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/ai/application/ai_generation_runtime.dart';
import 'package:void_scriptor/features/ai/application/generation_repository.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';

void main() {
  test('submit image prompt runs job and persists output in project', () async {
    final root = await Directory.systemTemp.createTemp('image-submit-');
    addTearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });
    final package = ProjectPackage(projectId: 'project-1', root: root);
    await package.databaseDirectory.create(recursive: true);
    final databaseService = ProjectDatabaseService();
    await databaseService.create(package.databaseFile.path);
    final database = await databaseService.open(package.databaseFile.path);
    addTearDown(database.close);
    final provider = _FileImageProvider(root);
    final runtime = await AiGenerationRuntime.open(
      database: database,
      package: package,
      registry: AiProviderRegistry([provider]),
    );
    addTearDown(runtime.dispose);

    final jobId = await runtime.submitImagePrompt(
      prompt: 'Kota Void di bawah hujan neon',
      providerId: provider.id,
    );

    final repository = GenerationRepository(database);
    final job = await repository.getJob(jobId);
    expect(job?.status, GenerationJobStatus.completed);
    final outputs = await repository.getOutputs(jobId);
    expect(outputs, hasLength(1));
    expect(outputs.single.outputType, 'image');
    final outputPath = outputs.single.localPath;
    expect(outputPath, isNotNull);
    expect(await File(package.resolve(outputPath!)).exists(), isTrue);
    expect(await File(package.resolve(outputPath)).readAsBytes(), _pngBytes);
  });
}

const _pngBytes = <int>[0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a];

class _FileImageProvider with AiStreamingFallback implements AiProvider {
  _FileImageProvider(this.root);

  final Directory root;

  @override
  String get id => 'file-image';

  @override
  String get displayName => 'File Image';

  @override
  Set<AiCapability> get capabilities => {AiCapability.imageGeneration};

  @override
  Future<List<AiModelInfo>> listModels() async => const [];

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    final file = File('${root.path}/provider-output.png');
    await file.writeAsBytes(_pngBytes);
    return AiGenerationResult(
      providerRequestId: request.jobId,
      outputs: [
        AiGeneratedOutput(
          type: AiOutputType.image,
          localPath: file.path,
          mimeType: 'image/png',
        ),
      ],
    );
  }

  @override
  Future<void> cancel(String requestId) async {}

  @override
  bool validateTarget(PromptTarget target) {
    if (target != PromptTarget.image) {
      throw UnsupportedError('Image only');
    }
    return true;
  }
}
