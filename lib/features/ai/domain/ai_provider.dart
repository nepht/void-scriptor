enum AiCapability {
  text,
  image,
  video,
  vision,
  negativePrompt,
  referenceImages,
}

class AiTextRequest {
  const AiTextRequest({
    required this.prompt,
    this.systemPrompt,
    this.temperature,
  });
  final String prompt;
  final String? systemPrompt;
  final double? temperature;
}

class AiTextResult {
  const AiTextResult({required this.text, this.providerRequestId});
  final String text;
  final String? providerRequestId;
}

abstract interface class AiProvider {
  String get id;
  String get displayName;
  Set<AiCapability> get capabilities;
  Future<AiTextResult> generateText(AiTextRequest request);
}

class AiProviderRegistry {
  final Map<String, AiProvider> _providers = {};
  void register(AiProvider provider) => _providers[provider.id] = provider;
  AiProvider? get(String id) => _providers[id];
  List<AiProvider> get all => _providers.values.toList(growable: false);
}
