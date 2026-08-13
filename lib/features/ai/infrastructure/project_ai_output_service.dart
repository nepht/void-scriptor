import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/persistence/project_paths.dart';
import '../domain/ai_provider.dart';
import '../domain/generation_job.dart';
import '../application/generation_job_executor.dart';

class ProjectAiOutputService implements AiOutputService {
  ProjectAiOutputService({required this.paths});
  final ProjectPaths paths;

  @override
  Future<SavedGenerationOutput> persist({
    required GenerationJob job,
    required AiGeneratedOutput output,
    required int index,
  }) async {
    final project = await paths.project(job.projectId);
    final directory = Directory(
      p.join(project.path, 'assets', 'ai', 'generations', job.id),
    );
    await directory.create(recursive: true);
    final extension = _extension(output.mimeType, output.type);
    final file = File(p.join(directory.path, 'output_${index + 1}.$extension'));
    if (output.localPath != null) {
      await File(output.localPath!).copy(file.path);
    } else if (output.remoteUrl != null) {
      throw StateError(
        'Remote output download requires an injected HTTP downloader.',
      );
    } else if (output.text != null) {
      await file.writeAsString(output.text!);
    } else {
      throw StateError(
        'Provider output has no local path, remote URL, or text.',
      );
    }
    final metadata = File(p.join(directory.path, 'metadata.json'));
    await metadata.writeAsString(
      jsonEncode({
        'jobId': job.id,
        'provider': job.providerId,
        'model': job.modelId,
        'promptHistoryId': job.promptHistoryId,
        'outputIndex': index,
        'outputType': output.type.name,
        'mimeType': output.mimeType,
        'createdAt': DateTime.now().toIso8601String(),
      }),
    );
    return SavedGenerationOutput(
      id: '${job.id}-$index',
      jobId: job.id,
      outputType: output.type.name,
      localPath: file.path,
      mimeType: output.mimeType,
    );
  }

  String _extension(String? mime, AiOutputType type) {
    if (mime == 'image/jpeg') return 'jpg';
    if (mime == 'image/webp') return 'webp';
    if (mime == 'image/png') return 'png';
    return switch (type) {
      AiOutputType.image => 'png',
      AiOutputType.video => 'mp4',
      AiOutputType.audio => 'wav',
      AiOutputType.text => 'txt',
      AiOutputType.file => 'bin',
    };
  }
}
