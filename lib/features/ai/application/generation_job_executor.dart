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
typedef PostGenerationHook =
    Future<void> Function(GenerationJob job, SavedGenerationOutput output);

class GenerationCancelledException implements Exception {
  const GenerationCancelledException(this.jobId);
  final String jobId;

  @override
  String toString() => 'Generation job $jobId was cancelled.';
}

class GenerationJobExecutor {
  GenerationJobExecutor({
    required this.registry,
    required this.repository,
    required this.outputService,
    required this.promptLoader,
    this.postGenerationHook,
  });
  final AiProviderRegistry registry;
  final GenerationJobRepository repository;
  final AiOutputService outputService;
  final PromptLoader promptLoader;
  final PostGenerationHook? postGenerationHook;
  final Set<String> _cancelled = {};

  Future<void> cancel(GenerationJob job) async {
    _cancelled.add(job.id);
    try {
      await registry.require(job.providerId).cancel(job.id);
    } finally {
      await repository.updateStatus(
        job.id,
        GenerationJobStatus.cancelled,
        progress: 0,
      );
    }
  }

  Future<void> execute(GenerationJob job) async {
    _cancelled.remove(job.id);
    await repository.updateStatus(
      job.id,
      GenerationJobStatus.running,
      progress: 0,
    );
    try {
      final provider = registry.require(job.providerId);
      final prompt = await promptLoader(job.promptHistoryId);
      _throwIfCancelled(job);
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
      _throwIfCancelled(job);
      for (var index = 0; index < result.outputs.length; index++) {
        _throwIfCancelled(job);
        final output = await outputService.persist(
          job: job,
          output: result.outputs[index],
          index: index,
        );
        _throwIfCancelled(job);
        await repository.saveOutput(output);
        await postGenerationHook?.call(job, output);
      }
      _throwIfCancelled(job);
      await repository.updateStatus(
        job.id,
        GenerationJobStatus.completed,
        progress: 1,
      );
    } catch (error) {
      final cancelled =
          error is GenerationCancelledException || _cancelled.contains(job.id);
      await repository.updateStatus(
        job.id,
        cancelled ? GenerationJobStatus.cancelled : GenerationJobStatus.failed,
        error: cancelled ? null : error.toString(),
      );
      rethrow;
    } finally {
      _cancelled.remove(job.id);
    }
  }

  void _throwIfCancelled(GenerationJob job) {
    if (_cancelled.contains(job.id)) {
      throw GenerationCancelledException(job.id);
    }
  }
}
