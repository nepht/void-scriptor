import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/ai_generation_queue_screen.dart';

void main() {
  testWidgets('queue screen submits an image prompt to selected provider', (
    tester,
  ) async {
    String? submittedPrompt;
    String? submittedProvider;

    await tester.pumpWidget(
      MaterialApp(
        home: AiGenerationQueueScreen(
          jobs: const [],
          imageProviderIds: const ['openai', 'comfyui'],
          onSubmitImage: ({required prompt, required providerId}) async {
            submittedPrompt = prompt;
            submittedProvider = providerId;
          },
        ),
      ),
    );

    expect(find.widgetWithText(FilledButton, 'Generate Image'), findsOneWidget);
    await tester.enterText(
      find.bySemanticsLabel('Image prompt'),
      'Kota Void di bawah hujan neon',
    );
    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('comfyui').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Generate Image'));
    await tester.pumpAndSettle();

    expect(submittedPrompt, 'Kota Void di bawah hujan neon');
    expect(submittedProvider, 'comfyui');
    expect(find.text('Image generation submitted.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('image submission form does not overflow at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: AiGenerationQueueScreen(
          jobs: const [],
          imageProviderIds: const ['openai', 'comfyui'],
          onSubmitImage: ({required prompt, required providerId}) async {},
        ),
      ),
    );

    expect(find.bySemanticsLabel('Image prompt'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Generate Image'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
