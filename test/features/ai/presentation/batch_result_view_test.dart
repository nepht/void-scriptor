import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/application/ai_batch.dart';
import 'package:void_scriptor/features/ai/presentation/batch_result_view.dart';

void main() {
  const results = [
    AiBatchResult(
      item: AiBatchItem(prompt: 'a', target: PromptTarget.story),
      success: true,
      output: AiGenerationResult(
        providerRequestId: 'r1',
        outputs: [AiGeneratedOutput(type: AiOutputType.text, text: 'ok')],
      ),
    ),
    AiBatchResult(
      item: AiBatchItem(prompt: 'b', target: PromptTarget.story),
      success: false,
      error: 'failed',
    ),
  ];

  testWidgets('shows per-item success and failure', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: BatchResultView(results: results)),
      ),
    );

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.textContaining('2 items'), findsOneWidget);
  });
}
