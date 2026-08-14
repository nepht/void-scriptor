import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/persistence/project_paths.dart';
import 'package:void_scriptor/database/project/project_database_service.dart';
import 'package:void_scriptor/features/ai/application/generation_repository.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';

void main() {
  test('generation job and outputs survive database restart', () async {
    final root = await Directory.systemTemp.createTemp('s18-ai-');
    addTearDown(() => root.delete(recursive: true));
    final paths = ProjectPaths(rootDirectory: root);
    final dbPath = (await paths.database('p1')).path;
    final service = ProjectDatabaseService();
    await service.create(dbPath);
    final first = await service.open(dbPath);
    final repository = GenerationRepository(first);
    final job = GenerationJob(
      id: 'job-1',
      projectId: 'p1',
      providerId: 'mock',
      modelId: 'mock-image',
      promptHistoryId: 'history-1',
      status: GenerationJobStatus.completed,
      progress: 1,
      createdAt: DateTime.utc(2026),
    );
    await repository.saveJob(job);
    await repository.saveOutput(
      jobId: job.id,
      outputId: 'output-1',
      outputType: 'image',
      localPath: 'assets/ai/generations/job-1/output_01.png',
      mimeType: 'image/png',
    );
    await repository.saveInput(
      jobId: job.id,
      inputId: 'input-1',
      inputType: 'character',
      sourceId: 'char-1',
      snapshotData: '{"name":"Qowner"}',
    );
    await repository.saveJob(
      GenerationJob(
        id: 'foreign-job',
        projectId: 'p2',
        providerId: 'mock',
        promptHistoryId: 'history-2',
        status: GenerationJobStatus.queued,
        createdAt: DateTime.utc(2026, 1, 2),
      ),
    );
    expect((await repository.listProjectJobs('p1')).map((item) => item.id), [
      'job-1',
    ]);
    expect(
      (await repository.watchProjectJobs('p1').first).map((item) => item.id),
      ['job-1'],
    );
    await first.close();
    final second = await service.open(dbPath);
    addTearDown(second.close);
    final restored = GenerationRepository(second);
    expect(
      (await restored.getJob(job.id))?.status,
      GenerationJobStatus.completed,
    );
    expect(
      (await restored.getOutputs(job.id)).single.localPath,
      contains('output_01.png'),
    );
    expect(
      (await restored.getInputs(job.id)).single.snapshotData,
      contains('Qowner'),
    );
    expect(second.schemaVersion, 35);
  });
}
