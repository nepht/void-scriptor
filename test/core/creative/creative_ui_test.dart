import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/creative/presentation/creative_os_panel.dart';
import 'package:void_scriptor/core/creative/presentation/idea_list.dart';
import 'package:void_scriptor/core/creative/presentation/pipeline_view.dart';

void main() {
  testWidgets('CreativeOsPanel shows brief count and stage', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CreativeOsPanel(briefCount: 3, stage: 'outline')),
      ),
    );
    expect(find.text('Creative OS'), findsOneWidget);
    expect(find.textContaining('3'), findsWidgets);
    expect(find.text('Stage: outline'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('IdeaList shows ideas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: IdeaList(ideas: ['Warden rises', 'Frozen North'])),
      ),
    );
    expect(find.text('Warden rises'), findsOneWidget);
    expect(find.text('Frozen North'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PipelineView shows stages', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PipelineView(stages: ['idea', 'outline', 'draft', 'polish']),
        ),
      ),
    );
    expect(find.text('idea'), findsOneWidget);
    expect(find.text('polish'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
