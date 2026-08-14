import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/domain/prompt_preset.dart';

void main() {
  test('Sprint 23 AI targets expose audio, VFX, and dialogue presets', () {
    const provider = MockAiProvider();
    expect(
      () => provider.validateTarget(PromptTarget.audio),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      BuiltInPromptPresets.all.map((preset) => preset.target),
      containsAll([
        PromptTarget.vfx,
        PromptTarget.audio,
        PromptTarget.dialogue,
      ]),
    );
  });
}
