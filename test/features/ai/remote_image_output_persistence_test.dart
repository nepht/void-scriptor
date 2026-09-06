import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/project_package/project_package.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';
import 'package:void_scriptor/features/ai/infrastructure/project_ai_output_service.dart';

void main() {
  test('remote image output is downloaded into the project package', () async {
    final root = await Directory.systemTemp.createTemp('remote-image-output-');
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    const pngBytes = <int>[
      0x89,
      0x50,
      0x4e,
      0x47,
      0x0d,
      0x0a,
      0x1a,
      0x0a,
      0x00,
      0x00,
      0x00,
      0x00,
    ];
    server.listen((request) async {
      request.response.headers.contentType = ContentType('image', 'png');
      request.response.add(pngBytes);
      await request.response.close();
    });
    addTearDown(() async {
      await server.close(force: true);
      if (await root.exists()) await root.delete(recursive: true);
    });
    final package = ProjectPackage(projectId: 'project-1', root: root);
    final service = ProjectAiOutputService(package: package);
    addTearDown(service.dispose);
    final job = GenerationJob(
      id: 'image-job-1',
      projectId: 'project-1',
      providerId: 'openai',
      promptHistoryId: 'prompt-1',
      status: GenerationJobStatus.running,
      createdAt: DateTime.utc(2026),
    );

    final saved = await service.persist(
      job: job,
      output: AiGeneratedOutput(
        type: AiOutputType.image,
        remoteUrl: 'http://${server.address.host}:${server.port}/image.png',
        mimeType: 'image/png',
      ),
      index: 0,
    );

    expect(saved.localPath, 'assets/ai/generations/image-job-1/output_1.png');
    expect(
      await File(package.resolve(saved.localPath!)).readAsBytes(),
      pngBytes,
    );
  });
}
