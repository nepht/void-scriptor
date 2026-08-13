import '../../../../../core/security/credential_store.dart';
import '../../../domain/ai_provider.dart';

abstract interface class GeminiClient {
  Future<List<AiModelInfo>> listModels({required String apiKey});
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  });
}

class GeminiProvider implements AiProvider {
  GeminiProvider({required this.credentialStore, required this.client});
  final CredentialStore credentialStore;
  final GeminiClient client;
  static const credentialKey = 'ai.gemini.api_key';
  @override
  String get id => 'gemini';
  @override
  String get displayName => 'Gemini';
  @override
  Set<AiCapability> get capabilities => {
    AiCapability.textGeneration,
    AiCapability.imageGeneration,
    AiCapability.imageEditing,
    AiCapability.visionInput,
    AiCapability.referenceImages,
  };
  Future<String> _key() async {
    final value = await credentialStore.read(credentialKey);
    if (value == null || value.isEmpty) {
      throw StateError('Gemini credentials are not configured.');
    }
    return value;
  }

  @override
  Future<List<AiModelInfo>> listModels() async =>
      client.listModels(apiKey: await _key());
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    validateTarget(request.target);
    return client.generate(apiKey: await _key(), request: request);
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) {
    final required = target == PromptTarget.story
        ? AiCapability.textGeneration
        : target == PromptTarget.video
        ? AiCapability.videoGeneration
        : AiCapability.imageGeneration;
    if (!capabilities.contains(required)) {
      throw UnsupportedError(
        'Provider "$id" does not support target ${target.name}.',
      );
    }
    return true;
  }
}
