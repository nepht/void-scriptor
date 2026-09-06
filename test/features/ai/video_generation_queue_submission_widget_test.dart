import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/prompt_target.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_queue_screen.dart';

void main() {
  testWidgets('video generator is honest when no provider is available', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AiGenerationQueueScreen(
          jobs: [],
          mediaTarget: PromptTarget.video,
        ),
      ),
    );

    expect(
      find.text('No video generation provider is configured yet.'),
      findsOneWidget,
    );
    expect(find.byType(FilledButton), findsNothing);
  });

  testWidgets('video generator submits a video prompt', (tester) async {
    String? submittedPrompt;
    String? submittedProvider;
    await tester.pumpWidget(
      MaterialApp(
        home: AiGenerationQueueScreen(
          jobs: const [],
          mediaTarget: PromptTarget.video,
          videoProviderIds: const ['openai', 'gemini'],
          onSubmitVideo: ({required prompt, required providerId}) async {
            submittedPrompt = prompt;
            submittedProvider = providerId;
          },
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), 'A city moving at night');
    await tester.tap(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Generate Video'),
      ),
    );
    await tester.pumpAndSettle();

    expect(submittedPrompt, 'A city moving at night');
    expect(submittedProvider, 'openai');
    expect(find.text('Video generation submitted.'), findsOneWidget);
  });
}
