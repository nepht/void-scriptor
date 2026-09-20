import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/reference_inspector_panel.dart';

void main() {
  testWidgets('reference inspector preserves the required section order', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReferenceInspectorPanel(
            properties: [InspectorProperty('Name', 'Owner')],
            tags: ['lore', 'main-character'],
            quickNotes: 'Protagonist utama.',
            aiPrompt: 'full body, anime long...',
            linkedAssets: [
              InspectorAssetCount('Wardrobe', '12', Icons.checkroom_outlined),
              InspectorAssetCount('Weapons', '5', Icons.gavel_outlined),
            ],
          ),
        ),
      ),
    );

    expect(find.text('PROPERTIES'), findsOneWidget);
    expect(find.text('TAGS'), findsOneWidget);
    expect(find.text('QUICK NOTES'), findsOneWidget);
    expect(find.text('AI PROMPT (MAIN)'), findsOneWidget);
    expect(find.text('LINKED ASSETS'), findsOneWidget);
    expect(find.text('ACTIONS'), findsOneWidget);
    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('lore'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
