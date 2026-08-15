import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/domain/ai_provider.dart';
import 'package:void_scriptor/features/ai/presentation/model_picker.dart';

void main() {
  const models = [
    AiModelInfo(
      id: 'gpt-4',
      displayName: 'GPT-4',
      capabilities: {AiCapability.textGeneration},
    ),
    AiModelInfo(
      id: 'gpt-4o',
      displayName: 'GPT-4o',
      capabilities: {AiCapability.textGeneration, AiCapability.visionInput},
    ),
  ];

  testWidgets('shows selected model and lists options on tap', (tester) async {
    String? selected = 'gpt-4';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ModelPicker(
            models: models,
            selected: selected,
            onChanged: (id) => selected = id,
          ),
        ),
      ),
    );

    expect(find.text('GPT-4'), findsOneWidget);

    await tester.tap(find.byType(ModelPicker));
    await tester.pumpAndSettle();
    expect(find.text('GPT-4o'), findsOneWidget);

    await tester.tap(find.text('GPT-4o').last);
    await tester.pumpAndSettle();
    expect(selected, 'gpt-4o');
  });
}
