import '../domain/ai_provider.dart';

/// Regenerates an output with user feedback appended to the prompt (Step 28.17).
class RegenerateService {
  RegenerateService(this.provider);

  final AiProvider provider;

  Future<AiGenerationResult> regenerate({
    required String prompt,
    required String feedback,
    required PromptTarget target,
  }) {
    final combined = [
      prompt.trim(),
      if (feedback.trim().isNotEmpty) 'FEEDBACK: ${feedback.trim()}',
    ].join('\n\n');
    return provider.generate(
      AiGenerationRequest(jobId: 'regen', prompt: combined, target: target),
    );
  }
}
