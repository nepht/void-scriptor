import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/ai/application/ai_generation_runtime.dart';
import 'package:void_scriptor/features/ai/application/generation_repository.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';

void main() {
  test('runtime recovers interrupted jobs without auto-running them', () async {
    final root = await Directory.systemTemp.createTemp('ai-runtime-');
    addTearDown(() => root.delete(recursive: true));
    final package = ProjectPackage(projectId: 'p1', root: root);
    await package.databaseDirectory.create(recursive: true);
    final service = ProjectDatabaseService();
    await service.create(package.databaseFile.path);
    final database = await service.open(package.databaseFile.path);
    addTearDown(database.close);
    final repository = GenerationRepository(database);
    await repository.saveJob(
      GenerationJob(
        id: 'interrupted',
        projectId: 'p1',
        providerId: 'mock',
        promptHistoryId: 'history',
        status: GenerationJobStatus.running,
        progress: .5,
        createdAt: DateTime.utc(2026),
      ),
    );

    final runtime = await AiGenerationRuntime.open(
      database: database,
      package: package,
      registry: AiProviderRegistry(const [MockAiProvider()]),
    );
    addTearDown(runtime.dispose);

    expect(
      (await repository.getJob('interrupted'))!.status,
      GenerationJobStatus.queued,
    );
    expect(await runtime.cancel('interrupted'), isTrue);
    expect(
      (await repository.getJob('interrupted'))!.status,
      GenerationJobStatus.cancelled,
    );
    await expectLater(
      runtime.enqueue(
        GenerationJob(
          id: 'foreign',
          projectId: 'p2',
          providerId: 'mock',
          promptHistoryId: 'history',
          status: GenerationJobStatus.queued,
          createdAt: DateTime.utc(2026),
        ),
      ),
      throwsStateError,
    );
  });
}
