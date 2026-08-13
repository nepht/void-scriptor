import '../../../domain/ai_provider.dart';

abstract interface class ComfyUiClient {
  Future<List<AiModelInfo>> listModels({required String baseUrl});
  Future<AiGenerationResult> generate({
    required String baseUrl,
    required AiGenerationRequest request,
  });
  Future<void> cancel({required String baseUrl, required String requestId});
}

class ComfyUiProvider implements AiProvider {
  ComfyUiProvider({
    required this.client,
    this.baseUrl = 'http://localhost:8188',
  });
  final ComfyUiClient client;
  final String baseUrl;
  @override
  String get id => 'comfyui';
  @override
  String get displayName => 'ComfyUI';
  @override
  Set<AiCapability> get capabilities => {
    AiCapability.imageGeneration,
    AiCapability.imageEditing,
    AiCapability.referenceImages,
    AiCapability.remoteCancellation,
  };
  @override
  Future<List<AiModelInfo>> listModels() => client.listModels(baseUrl: baseUrl);
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) {
    validateTarget(request.target);
    return client.generate(baseUrl: baseUrl, request: request);
  }

  @override
  Future<void> cancel(String requestId) =>
      client.cancel(baseUrl: baseUrl, requestId: requestId);
  @override
  bool validateTarget(PromptTarget target) {
    if (target == PromptTarget.video || target == PromptTarget.story) {
      throw UnsupportedError(
        'ComfyUI adapter currently supports image workflows only.',
      );
    }
    return true;
  }
}
