import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/security/credential_store.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/gemini/gemini_provider.dart';
import 'package:void_scriptor/features/ai/infrastructure/providers/openai/openai_provider.dart';
import 'package:void_scriptor/features/ai/presentation/ai_provider_workspace_screen.dart';

void main() {
  testWidgets('provider status is loaded without exposing credential values', (
    tester,
  ) async {
    final store = MemoryCredentialStore();
    await store.write(key: OpenAiProvider.credentialKey, value: 'secret-value');
    await tester.pumpWidget(
      MaterialApp(home: AiProviderWorkspaceScreen(credentialStore: store)),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI PROVIDERS'), findsOneWidget);
    expect(find.text('OpenAI'), findsOneWidget);
    expect(find.text('Credential configured'), findsOneWidget);
    expect(find.text('secret-value'), findsNothing);
    expect(find.text('Not configured'), findsOneWidget);
  });

  testWidgets('Configure stores cloud credentials and refreshes masked state', (
    tester,
  ) async {
    final store = MemoryCredentialStore();
    await tester.pumpWidget(
      MaterialApp(home: AiProviderWorkspaceScreen(credentialStore: store)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Configure').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Configure Gemini'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'gemini-secret');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(await store.read(GeminiProvider.credentialKey), 'gemini-secret');
    expect(find.text('Credential configured'), findsOneWidget);
    expect(find.text('gemini-secret'), findsNothing);
  });
}
