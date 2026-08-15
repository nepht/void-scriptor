import '../../../../../core/security/credential_store.dart';
import '../../../domain/ai_provider.dart';

abstract interface class OpenAiClient {
  Future<List<AiModelInfo>> listModels({required String apiKey});
  Future<AiGenerationResult> generate({
    required String apiKey,
    required AiGenerationRequest request,
  });
}

class OpenAiProvider with AiStreamingFallback implements AiProvider {
  OpenAiProvider({required this.credentialStore, required this.client});
  final CredentialStore credentialStore;
  final OpenAiClient client;
  static const credentialKey = 'ai.openai.api_key';

  @override
  String get id => 'openai';
  @override
  String get displayName => 'OpenAI';
  @override
  Set<AiCapability> get capabilities => {
    AiCapability.textGeneration,
    AiCapability.imageGeneration,
    AiCapability.imageEditing,
    AiCapability.visionInput,
    AiCapability.referenceImages,
  };

  Future<String> _requireKey() async {
    final key = await credentialStore.read(credentialKey);
    if (key == null || key.isEmpty) {
      throw StateError('OpenAI credentials are not configured.');
    }
    return key;
  }

  @override
  Future<List<AiModelInfo>> listModels() async =>
      client.listModels(apiKey: await _requireKey());
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async {
    validateTarget(request.target);
    return client.generate(apiKey: await _requireKey(), request: request);
  }

  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) {
    final required = switch (target) {
      PromptTarget.video => AiCapability.videoGeneration,
      PromptTarget.story => AiCapability.textGeneration,
      _ => AiCapability.imageGeneration,
    };
    if (!capabilities.contains(required)) {
      throw UnsupportedError(
        'Provider "$id" does not support target ${target.name}.',
      );
    }
    return true;
  }
}
