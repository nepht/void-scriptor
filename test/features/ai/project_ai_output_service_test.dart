import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';
import 'package:void_scriptor/features/ai/infrastructure/project_ai_output_service.dart';

void main() {
  test('AI outputs stay package-scoped and persist relative paths', () async {
    final root = await Directory.systemTemp.createTemp('ai-output-package-');
    addTearDown(() => root.delete(recursive: true));
    final package = ProjectPackage(projectId: 'p1', root: root);
    final source = File('${root.parent.path}/source-${root.path.hashCode}.txt');
    await source.writeAsString('generated text');
    addTearDown(() async {
      if (await source.exists()) await source.delete();
    });
    final service = ProjectAiOutputService(package: package);
    final job = GenerationJob(
      id: 'job-1',
      projectId: 'p1',
      providerId: 'mock',
      promptHistoryId: 'prompt-1',
      status: GenerationJobStatus.running,
      createdAt: DateTime.utc(2026),
    );

    final saved = await service.persist(
      job: job,
      output: AiGeneratedOutput(
        type: AiOutputType.text,
        localPath: source.path,
        mimeType: 'text/plain',
      ),
      index: 0,
    );

    expect(saved.localPath, 'assets/ai/generations/job-1/output_1.txt');
    expect(
      await File(package.resolve(saved.localPath!)).readAsString(),
      'generated text',
    );
  });
}
