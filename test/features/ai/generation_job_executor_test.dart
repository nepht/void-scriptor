import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/application/generation_job_executor.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/generation_job.dart';

void main() {
  test('executor generates through registry and persists outputs', () async {
    final repository = FakeGenerationRepository();
    final outputService = FakeOutputService();
    final checked = <String>[];
    final executor = GenerationJobExecutor(
      registry: AiProviderRegistry([FakeProvider()]),
      repository: repository,
      outputService: outputService,
      promptLoader: (_) async =>
          const LoadedPrompt(prompt: 'prompt', target: PromptTarget.image),
      postGenerationHook: (job, output) async => checked.add(output.id),
    );
    await executor.execute(_job());
    expect(repository.statuses, [
      GenerationJobStatus.running,
      GenerationJobStatus.completed,
    ]);
    expect(outputService.saved, 1);
    expect(repository.outputs.single.outputType, 'image');
    expect(checked, ['o0']);
  });

  test('executor marks provider failure without saving outputs', () async {
    final repository = FakeGenerationRepository();
    final executor = GenerationJobExecutor(
      registry: AiProviderRegistry([FailingProvider()]),
      repository: repository,
      outputService: FakeOutputService(),
      promptLoader: (_) async =>
          const LoadedPrompt(prompt: 'prompt', target: PromptTarget.image),
    );
    await expectLater(executor.execute(_job()), throwsA(isA<Exception>()));
    expect(repository.statuses.last, GenerationJobStatus.failed);
  });
  test('executor forwards running cancellation and persists status', () async {
    final repository = FakeGenerationRepository();
    final provider = FakeProvider();
    final executor = GenerationJobExecutor(
      registry: AiProviderRegistry([provider]),
      repository: repository,
      outputService: FakeOutputService(),
      promptLoader: (_) async =>
          const LoadedPrompt(prompt: 'prompt', target: PromptTarget.image),
    );

    await executor.cancel(_job());

    expect(provider.cancelledRequestIds, ['job-1']);
    expect(repository.statuses.last, GenerationJobStatus.cancelled);
  });

  test('late provider result cannot overwrite cancelled status', () async {
    final repository = FakeGenerationRepository();
    final provider = BlockingProvider();
    final outputService = FakeOutputService();
    final executor = GenerationJobExecutor(
      registry: AiProviderRegistry([provider]),
      repository: repository,
      outputService: outputService,
      promptLoader: (_) async =>
          const LoadedPrompt(prompt: 'prompt', target: PromptTarget.image),
    );
    final execution = executor.execute(_job());
    await provider.started.future;

    await executor.cancel(_job());
    provider.release.complete();

    await expectLater(execution, throwsA(isA<GenerationCancelledException>()));
    expect(outputService.saved, 0);
    expect(repository.statuses, isNot(contains(GenerationJobStatus.completed)));
    expect(repository.statuses.last, GenerationJobStatus.cancelled);
  });
}

GenerationJob _job() => GenerationJob(
  id: 'job-1',
  projectId: 'p1',
  providerId: 'fake',
  promptHistoryId: 'h1',
  status: GenerationJobStatus.queued,
  createdAt: DateTime.utc(2026),
);

class FakeProvider with AiStreamingFallback implements AiProvider {
  final cancelledRequestIds = <String>[];

  @override
  String get id => 'fake';
  @override
  String get displayName => 'Fake';
  @override
  Set<AiCapability> get capabilities => {AiCapability.imageGeneration};
  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(
        providerRequestId: 'r1',
        outputs: [
          AiGeneratedOutput(
            type: AiOutputType.image,
            remoteUrl: 'https://example.invalid/a.png',
            mimeType: 'image/png',
          ),
        ],
      );
  @override
  Future<void> cancel(String requestId) async {
    cancelledRequestIds.add(requestId);
  }

  @override
  bool validateTarget(PromptTarget target) => true;
}

class FailingProvider extends FakeProvider {
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      throw Exception('provider failed');
}

class BlockingProvider extends FakeProvider {
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    started.complete();
    await release.future;
    return super.generate(request);
  }
}

class FakeGenerationRepository implements GenerationJobRepository {
  final statuses = <GenerationJobStatus>[];
  final outputs = <SavedGenerationOutput>[];
  @override
  Future<void> updateStatus(
    String id,
    GenerationJobStatus status, {
    String? error,
    double? progress,
  }) async => statuses.add(status);
  @override
  Future<void> saveOutput(SavedGenerationOutput output) async =>
      outputs.add(output);
}

class FakeOutputService implements AiOutputService {
  int saved = 0;
  @override
  Future<SavedGenerationOutput> persist({
    required GenerationJob job,
    required AiGeneratedOutput output,
    required int index,
  }) async {
    saved++;
    return SavedGenerationOutput(
      id: 'o$index',
      jobId: job.id,
      outputType: output.type.name,
      localPath: 'assets/ai/generations/${job.id}/output_$index.png',
    );
  }
}
