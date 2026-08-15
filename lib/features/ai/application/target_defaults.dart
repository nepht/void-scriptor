import '../domain/prompt_target.dart';

class ProviderModelChoice {
  const ProviderModelChoice({required this.providerId, this.modelId});
  final String providerId;
  final String? modelId;
}

/// Default provider+model per target (Step 28.12), with optional overrides.
class TargetDefaults {
  const TargetDefaults({this.overrides = const {}});

  final Map<PromptTarget, ProviderModelChoice> overrides;

  static const _defaults = <PromptTarget, ProviderModelChoice>{
    PromptTarget.image: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.video: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.story: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.characterConsistency: ProviderModelChoice(
      providerId: 'openai',
    ),
    PromptTarget.environment: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.wardrobe: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.weapon: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.creature: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.vehicle: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.prop: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.vfx: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.audio: ProviderModelChoice(providerId: 'openai'),
    PromptTarget.dialogue: ProviderModelChoice(providerId: 'openai'),
  };

  ProviderModelChoice? defaultFor(PromptTarget target) =>
      overrides[target] ?? _defaults[target];
}
