import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/knowledge/presentation/knowledge_engine_panel.dart';
import 'package:void_scriptor/core/knowledge/presentation/knowledge_entity_list.dart';
import 'package:void_scriptor/core/knowledge/presentation/universe_validation_view.dart';

void main() {
  testWidgets('KnowledgeEnginePanel shows entity count', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KnowledgeEnginePanel(entityCount: 12, relationCount: 8),
        ),
      ),
    );
    expect(find.text('Knowledge Engine'), findsOneWidget);
    expect(find.textContaining('12'), findsWidgets);
    expect(find.textContaining('8'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('KnowledgeEntityList shows entities', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: KnowledgeEntityList(entities: ['Kael', 'Mira', 'North']),
        ),
      ),
    );
    expect(find.text('Kael'), findsOneWidget);
    expect(find.text('Mira'), findsOneWidget);
    expect(find.text('North'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('UniverseValidationView shows violations', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: UniverseValidationView(
            violations: ['Duplicate character "Kael"'],
          ),
        ),
      ),
    );
    expect(find.textContaining('Kael'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
