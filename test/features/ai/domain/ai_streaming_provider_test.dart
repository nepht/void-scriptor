import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/ai_streaming.dart';

class _NonStreamingProvider with AiStreamingFallback implements AiProvider {
  @override
  String get id => 'non-streaming';
  @override
  String get displayName => 'Non Streaming';
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};

  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(
        providerRequestId: 'r1',
        outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'full')],
      );
  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => true;
}

class _StreamingProvider implements AiProvider {
  @override
  String get id => 'streaming';
  @override
  String get displayName => 'Streaming';
  @override
  Set<AiCapability> get capabilities => {AiCapability.streaming};

  @override
  Future<List<AiModelInfo>> listModels() async => const [];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(
        providerRequestId: 'r2',
        outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'full')],
      );
  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) => true;

  @override
  Stream<AiStreamingChunk> streamGenerate(AiGenerationRequest request) async* {
    yield const AiStreamingChunk.text('hel');
    yield const AiStreamingChunk.text('lo');
    yield const AiStreamingChunk.done();
  }
}

class _NonStreamingArtifactProvider extends _NonStreamingProvider {
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(
        providerRequestId: 'r3',
        outputs: [
          AiGeneratedOutput(
            type: AiOutputType.image,
            remoteUrl: 'mock://image',
            mimeType: 'image/png',
          ),
        ],
      );
}

AiGenerationRequest _request(String jobId) => AiGenerationRequest(
  jobId: jobId,
  prompt: 'test',
  target: PromptTarget.story,
);

void main() {
  test('non-streaming provider falls back to text + done chunks', () async {
    final provider = _NonStreamingProvider();
    final chunks = await provider.streamGenerate(_request('j1')).toList();
    expect(chunks, hasLength(2));
    expect(chunks.first.type, AiStreamChunkType.text);
    expect(chunks.first.text, 'full');
    expect(chunks.last.type, AiStreamChunkType.done);
  });

  test('fallback preserves non-text output metadata', () async {
    final provider = _NonStreamingArtifactProvider();
    final chunks = await provider.streamGenerate(_request('j3')).toList();
    expect(chunks.first.type, AiStreamChunkType.image);
    expect(chunks.first.remoteUrl, 'mock://image');
    expect(chunks.first.mimeType, 'image/png');
    expect(chunks.last.type, AiStreamChunkType.done);
  });

  test('streaming provider emits ordered text chunks', () async {
    final provider = _StreamingProvider();
    final chunks = await provider.streamGenerate(_request('j2')).toList();
    expect(chunks.map((c) => c.text).whereType<String>().toList(), [
      'hel',
      'lo',
    ]);
    expect(chunks.last.type, AiStreamChunkType.done);
  });
}
