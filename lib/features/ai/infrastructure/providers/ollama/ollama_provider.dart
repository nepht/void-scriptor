import '../../../domain/ai_provider.dart';

abstract interface class OllamaClient {
  Future<List<AiModelInfo>> listModels({required String baseUrl});
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  });
}

class OllamaProvider implements AiProvider {
  OllamaProvider({
    required this.client,
    this.baseUrl = 'http://localhost:11434',
  });
  final OllamaClient client;
  final String baseUrl;
  @override
  String get id => 'ollama';
  @override
  String get displayName => 'Ollama';
  @override
  Set<AiCapability> get capabilities => {AiCapability.textGeneration};
  @override
  Future<List<AiModelInfo>> listModels() => client.listModels(baseUrl: baseUrl);
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) {
    validateTarget(request.target);
    return client.generate(baseUrl: baseUrl, request: request);
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) {
    if (target != PromptTarget.story) {
      throw UnsupportedError('Ollama supports text generation only.');
    }
    return true;
  }
}
