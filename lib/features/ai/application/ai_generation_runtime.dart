import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../../../core/project_package/project_package.dart';
import '../../../core/security/credential_store.dart';
import '../../../database/project/project_database.dart';
import '../domain/ai_provider.dart';
import '../domain/ai_provider_settings.dart';
import '../domain/generation_job.dart';
import '../infrastructure/project_ai_output_service.dart';
import '../infrastructure/providers/comfyui/comfyui_http_client.dart';
import '../infrastructure/providers/comfyui/comfyui_provider.dart';
import '../infrastructure/providers/gemini/gemini_http_client.dart';
import '../infrastructure/providers/gemini/gemini_provider.dart';
import '../infrastructure/providers/ollama/ollama_http_client.dart';
import '../infrastructure/providers/ollama/ollama_provider.dart';
import '../infrastructure/providers/openai/openai_http_client.dart';
import '../infrastructure/providers/openai/openai_provider.dart';
import 'ai_prompt_history_service.dart';
import 'generation_job_executor.dart';
import 'generation_queue.dart';
import 'generation_repository.dart';

class AiGenerationRuntime {
  AiGenerationRuntime._({
    required this.projectId,
    required this.repository,
    required this.executor,
    required this.queue,
    required this._promptHistory,
    required this._outputService,
    this._ownedHttpClient,
  });

  final String projectId;
  final GenerationRepository repository;
  final GenerationJobExecutor executor;
  final GenerationQueue queue;
  final AiPromptHistoryService _promptHistory;
  final ProjectAiOutputService _outputService;
  final http.Client? _ownedHttpClient;

  static Future<AiGenerationRuntime> open({
    required ProjectDatabase database,
    required ProjectPackage package,
    CredentialStore? credentialStore,
    AiProviderRegistry? registry,
  }) async {
    final store =
        credentialStore ?? const SecureCredentialStore(FlutterSecureStorage());
    http.Client? ownedClient;
    final resolvedRegistry =
        registry ??
        await _buildDefaultRegistry(
          store,
          ownedClientFactory: () {
            return ownedClient ??= http.Client();
          },
        );
    final repository = GenerationRepository(database);
    final promptHistory = AiPromptHistoryService(database);
    final outputService = ProjectAiOutputService(package: package);
    final executor = GenerationJobExecutor(
      registry: resolvedRegistry,
      repository: _ExecutorRepositoryAdapter(repository),
      outputService: outputService,
      promptLoader: (id) async {
        final row = await promptHistory.getHistory(id);
        if (row == null) {
          throw StateError('Prompt history $id does not exist.');
        }
        return LoadedPrompt(
          prompt: row.prompt,
          negativePrompt: row.negativePrompt,
          target: PromptTarget.values.byName(row.target),
        );
      },
    );
    final queue = GenerationQueue(
      executor: executor.execute,
      canceller: executor.cancel,
    );
    final runtime = AiGenerationRuntime._(
      projectId: package.projectId,
      repository: repository,
      executor: executor,
      queue: queue,
      promptHistory: promptHistory,
      outputService: outputService,
      ownedHttpClient: ownedClient,
    );
    await runtime._recoverInterruptedJobs();
    return runtime;
  }

  static Future<AiProviderRegistry> _buildDefaultRegistry(
    CredentialStore store, {
    required http.Client Function() ownedClientFactory,
  }) async {
    final client = ownedClientFactory();
    final ollamaEndpoint =
        await store.read(AiProviderSettingKeys.ollamaEndpoint) ??
        AiProviderSettingKeys.defaultOllamaEndpoint;
    final comfyUiEndpoint =
        await store.read(AiProviderSettingKeys.comfyUiEndpoint) ??
        AiProviderSettingKeys.defaultComfyUiEndpoint;
    return AiProviderRegistry([
      OpenAiProvider(
        credentialStore: store,
        client: HttpOpenAiClient(client: client),
      ),
      GeminiProvider(
        credentialStore: store,
        client: HttpGeminiClient(client: client),
      ),
      OllamaProvider(
        client: HttpOllamaClient(client: client),
        baseUrl: ollamaEndpoint,
      ),
      ComfyUiProvider(
        client: HttpComfyUiClient(client: client),
        baseUrl: comfyUiEndpoint,
      ),
    ]);
  }

  Stream<List<GenerationJob>> watchJobs() =>
      repository.watchProjectJobs(projectId);

  Future<void> enqueue(GenerationJob job) async {
    _guardProject(job);
    final queued = job.copyWith(
      status: GenerationJobStatus.queued,
      progress: 0,
      clearError: true,
    );
    await repository.saveJob(queued);
    queue.enqueue(queued);
  }

  Future<void> runQueue() => queue.drain();

  Future<String> submitImagePrompt({
    required String prompt,
    required String providerId,
    String? modelId,
    String negativePrompt = '',
  }) => submitPrompt(
    target: PromptTarget.image,
    prompt: prompt,
    providerId: providerId,
    modelId: modelId,
    negativePrompt: negativePrompt,
  );

  Future<String> submitVideoPrompt({
    required String prompt,
    required String providerId,
    String? modelId,
    String negativePrompt = '',
  }) => submitPrompt(
    target: PromptTarget.video,
    prompt: prompt,
    providerId: providerId,
    modelId: modelId,
    negativePrompt: negativePrompt,
  );

  Future<String> submitPrompt({
    required PromptTarget target,
    required String prompt,
    required String providerId,
    String? modelId,
    String negativePrompt = '',
  }) async {
    final normalizedPrompt = prompt.trim();
    if (normalizedPrompt.isEmpty) {
      throw ArgumentError.value(prompt, 'prompt', 'Prompt must not be empty.');
    }
    final promptHistoryId = await _promptHistory.savePrompt(
      projectId: projectId,
      target: target.name,
      prompt: normalizedPrompt,
      negativePrompt: negativePrompt,
      provider: providerId,
      model: modelId,
    );
    final job = GenerationJob(
      id: const Uuid().v4(),
      projectId: projectId,
      providerId: providerId,
      modelId: modelId,
      promptHistoryId: promptHistoryId,
      status: GenerationJobStatus.queued,
      createdAt: DateTime.now(),
    );
    await enqueue(job);
    await runQueue();
    return job.id;
  }

  Future<bool> cancel(String jobId) async {
    final job = await repository.getJob(jobId);
    if (job == null || job.projectId != projectId) return false;
    final handled = await queue.cancel(jobId);
    if (!handled && job.status == GenerationJobStatus.running) {
      await executor.cancel(job);
    }
    if (!handled && job.status != GenerationJobStatus.running) return false;
    await repository.updateStatus(jobId, GenerationJobStatus.cancelled);
    return true;
  }

  Future<bool> retry(String jobId) async {
    final job = await repository.getJob(jobId);
    if (job == null ||
        job.projectId != projectId ||
        job.status != GenerationJobStatus.failed) {
      return false;
    }
    final retriedInMemory = queue.retry(jobId);
    if (!retriedInMemory) {
      queue.enqueue(
        job.copyWith(
          status: GenerationJobStatus.queued,
          progress: 0,
          clearError: true,
        ),
      );
    }
    await repository.updateStatus(
      jobId,
      GenerationJobStatus.queued,
      progress: 0,
    );
    return true;
  }

  Future<void> _recoverInterruptedJobs() async {
    final jobs = await repository.listProjectJobs(projectId);
    for (final job in jobs) {
      if (job.status != GenerationJobStatus.queued &&
          job.status != GenerationJobStatus.running) {
        continue;
      }
      final recovered = job.copyWith(
        status: GenerationJobStatus.queued,
        progress: 0,
      );
      if (job.status == GenerationJobStatus.running) {
        await repository.updateStatus(
          job.id,
          GenerationJobStatus.queued,
          progress: 0,
        );
      }
      queue.enqueue(recovered);
    }
  }

  void _guardProject(GenerationJob job) {
    if (job.projectId != projectId) {
      throw StateError(
        'Generation job ${job.id} belongs to ${job.projectId}, not $projectId.',
      );
    }
  }

  void dispose() {
    _outputService.dispose();
    _ownedHttpClient?.close();
  }
}

class _ExecutorRepositoryAdapter implements GenerationJobRepository {
  const _ExecutorRepositoryAdapter(this.repository);
  final GenerationRepository repository;

  @override
  Future<void> updateStatus(
    String id,
    GenerationJobStatus status, {
    String? error,
    double? progress,
  }) => repository.updateStatus(id, status, error: error, progress: progress);

  @override
  Future<void> saveOutput(SavedGenerationOutput output) =>
      repository.saveOutput(
        jobId: output.jobId,
        outputId: output.id,
        outputType: output.outputType,
        localPath: output.localPath,
        remoteUrl: output.remoteUrl,
        mimeType: output.mimeType,
      );
}
