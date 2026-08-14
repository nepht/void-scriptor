import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../../../core/project_package/project_package.dart';
import '../domain/ai_provider.dart';
import '../domain/generation_job.dart';
import '../application/generation_job_executor.dart';

class ProjectAiOutputService implements AiOutputService {
  ProjectAiOutputService({required this.package});
  final ProjectPackage package;

  @override
  Future<SavedGenerationOutput> persist({
    required GenerationJob job,
    required AiGeneratedOutput output,
    required int index,
  }) async {
    if (job.projectId != package.projectId) {
      throw StateError(
        'AI job ${job.id} belongs to ${job.projectId}, not ${package.projectId}.',
      );
    }
    final relativeDirectory = p.posix.join(
      'assets',
      'ai',
      'generations',
      job.id,
    );
    final directory = Directory(package.resolve(relativeDirectory));
    await directory.create(recursive: true);
    final extension = _extension(output.mimeType, output.type);
    final file = File(p.join(directory.path, 'output_${index + 1}.$extension'));
    if (output.localPath != null) {
      final sourcePath = p.isAbsolute(output.localPath!)
          ? output.localPath!
          : package.resolve(output.localPath!);
      await File(sourcePath).copy(file.path);
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
    final relativeOutputPath = p.posix.join(
      relativeDirectory,
      'output_${index + 1}.$extension',
    );
    return SavedGenerationOutput(
      id: '${job.id}-$index',
      jobId: job.id,
      outputType: output.type.name,
      localPath: relativeOutputPath,
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
