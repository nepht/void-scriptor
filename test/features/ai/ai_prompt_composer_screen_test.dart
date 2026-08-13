import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:void_scriptor/features/ai/presentation/ai_prompt_composer_screen.dart';

void main() {
  testWidgets('composer renders responsive controls and editable prompt', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AiPromptComposerScreen()));
    expect(find.text('AI Prompt Composer'), findsOneWidget);
    expect(find.text('CONTEXT'), findsOneWidget);
    expect(find.text('MASTER PROMPT'), findsOneWidget);
    await tester.tap(find.byTooltip('Generate Prompt'));
    await tester.pump();
    expect(find.textContaining('No scene context selected'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'manual edit');
    await tester.pump();
    expect(find.textContaining('Modified'), findsOneWidget);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pump();
    final exception = tester.takeException();
    debugPrint('NARROW_EXCEPTION: $exception');
    expect(exception, isNull);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });
}
