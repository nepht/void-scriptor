import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:void_scriptor/features/ai/presentation/ai_provider_workspace_screen.dart';

void main() {
  testWidgets(
    'provider workspace shows providers and masked credential state',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: AiProviderWorkspaceScreen()),
      );
      expect(find.text('AI PROVIDERS'), findsOneWidget);
      expect(find.text('OpenAI'), findsOneWidget);
      expect(find.text('Credential configured'), findsOneWidget);
      expect(find.text('secret-value'), findsNothing);
    },
  );
}
