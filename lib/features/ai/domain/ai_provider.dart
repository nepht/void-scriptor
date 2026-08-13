import 'prompt_preset.dart';
import 'prompt_target.dart';
export 'prompt_target.dart';

enum AiProviderType { openAi, gemini, ollama, comfyUi, custom }

enum AiCapability {
  textGeneration,
  imageGeneration,
  imageEditing,
  videoGeneration,
  visionInput,
  referenceImages,
  negativePrompt,
  streaming,
  remoteCancellation,
}

class AiProviderConfig {
  const AiProviderConfig({
    required this.id,
    required this.type,
    required this.displayName,
    required this.enabled,
    this.baseUrl,
    this.defaultModel,
  });
  final String id;
  final AiProviderType type;
  final String displayName;
  final bool enabled;
  final String? baseUrl;
  final String? defaultModel;
}

class AiModelInfo {
  const AiModelInfo({
    required this.id,
    required this.displayName,
    required this.capabilities,
  });
  final String id;
  final String displayName;
  final Set<AiCapability> capabilities;
}

class AiGenerationRequest {
  const AiGenerationRequest({
    required this.jobId,
    required this.prompt,
    required this.target,
    this.negativePrompt,
    this.model,
    this.referenceImages = const [],
    this.parameters = const {},
  });
  final String jobId;
  final String prompt;
  final PromptTarget target;
  final String? negativePrompt;
  final String? model;
  final List<AiReferenceImage> referenceImages;
  final Map<String, Object?> parameters;
}

enum AiOutputType { text, image, video, audio, file }

class AiGeneratedOutput {
  const AiGeneratedOutput({
    required this.type,
    this.text,
    this.remoteUrl,
    this.localPath,
    this.mimeType,
  });
  final AiOutputType type;
  final String? text;
  final String? remoteUrl;
  final String? localPath;
  final String? mimeType;
}

class AiGenerationResult {
  const AiGenerationResult({
    required this.providerRequestId,
    required this.outputs,
    this.metadata = const {},
  });
  final String providerRequestId;
  final List<AiGeneratedOutput> outputs;
  final Map<String, Object?> metadata;
}

abstract interface class AiProvider {
  String get id;
  String get displayName;
  Set<AiCapability> get capabilities;
  Future<List<AiModelInfo>> listModels();
  Future<AiGenerationResult> generate(AiGenerationRequest request);
  Future<void> cancel(String requestId);
  bool validateTarget(PromptTarget target);
}

class AiProviderRegistry {
  AiProviderRegistry(Iterable<AiProvider> providers)
    : _providers = {for (final provider in providers) provider.id: provider};
  final Map<String, AiProvider> _providers;
  AiProvider require(String id) =>
      _providers[id] ??
      (throw StateError('AI provider "$id" is not registered.'));
  AiProvider? get(String id) => _providers[id];
  List<AiProvider> get all => List.unmodifiable(_providers.values);
}

class MockAiProvider implements AiProvider {
  const MockAiProvider();
  @override
  String get id => 'mock';
  @override
  String get displayName => 'Mock Provider';
  @override
  Set<AiCapability> get capabilities => {
    AiCapability.textGeneration,
    AiCapability.imageGeneration,
  };
  @override
  Future<List<AiModelInfo>> listModels() async => const [
    AiModelInfo(
      id: 'mock-image',
      displayName: 'Mock Image',
      capabilities: {AiCapability.imageGeneration},
    ),
  ];
  @override
  Future<AiGenerationResult> generate(AiGenerationRequest request) async =>
      const AiGenerationResult(
        providerRequestId: 'mock-request',
        outputs: [
          AiGeneratedOutput(
            type: AiOutputType.text,
            text: 'Mock generation complete.',
          ),
        ],
      );
  @override
  Future<void> cancel(String requestId) async {}
  @override
  bool validateTarget(PromptTarget target) {
    final required = switch (target) {
      PromptTarget.video => AiCapability.videoGeneration,
      PromptTarget.image ||
      PromptTarget.characterConsistency ||
      PromptTarget.environment ||
      PromptTarget.wardrobe ||
      PromptTarget.weapon => AiCapability.imageGeneration,
      PromptTarget.story => AiCapability.textGeneration,
    };
    if (!capabilities.contains(required)) {
      throw UnsupportedError(
        'Provider "$id" does not support target ${target.name}.',
      );
    }
    return true;
  }
}
