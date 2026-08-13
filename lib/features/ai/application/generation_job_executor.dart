import '../domain/ai_provider.dart';
import '../domain/generation_job.dart';

class LoadedPrompt {
  const LoadedPrompt({
    required this.prompt,
    required this.target,
    this.negativePrompt,
  });
  final String prompt;
  final PromptTarget target;
  final String? negativePrompt;
}

class SavedGenerationOutput {
  const SavedGenerationOutput({
    required this.id,
    required this.jobId,
    required this.outputType,
    this.localPath,
    this.remoteUrl,
    this.mimeType,
  });
  final String id;
  final String jobId;
  final String outputType;
  final String? localPath;
  final String? remoteUrl;
  final String? mimeType;
}

abstract interface class GenerationJobRepository {
  Future<void> updateStatus(
    String id,
    GenerationJobStatus status, {
    String? error,
    double? progress,
  });
  Future<void> saveOutput(SavedGenerationOutput output);
}

abstract interface class AiOutputService {
  Future<SavedGenerationOutput> persist({
    required GenerationJob job,
    required AiGeneratedOutput output,
    required int index,
  });
}

typedef PromptLoader = Future<LoadedPrompt> Function(String promptHistoryId);

class GenerationJobExecutor {
  GenerationJobExecutor({
    required this.registry,
    required this.repository,
    required this.outputService,
    required this.promptLoader,
  });
  final AiProviderRegistry registry;
  final GenerationJobRepository repository;
  final AiOutputService outputService;
  final PromptLoader promptLoader;

  Future<void> execute(GenerationJob job) async {
    await repository.updateStatus(
      job.id,
      GenerationJobStatus.running,
      progress: 0,
    );
    try {
      final provider = registry.require(job.providerId);
      final prompt = await promptLoader(job.promptHistoryId);
      provider.validateTarget(prompt.target);
      final result = await provider.generate(
        AiGenerationRequest(
          jobId: job.id,
          prompt: prompt.prompt,
          target: prompt.target,
          negativePrompt: prompt.negativePrompt,
          model: job.modelId,
        ),
      );
      for (var index = 0; index < result.outputs.length; index++) {
        final output = await outputService.persist(
          job: job,
          output: result.outputs[index],
          index: index,
        );
        await repository.saveOutput(output);
      }
      await repository.updateStatus(
        job.id,
        GenerationJobStatus.completed,
        progress: 1,
      );
    } catch (error) {
      await repository.updateStatus(
        job.id,
        GenerationJobStatus.failed,
        error: error.toString(),
      );
      rethrow;
    }
  }
}
