import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/project_resilience/presentation/project_resilience_center_screen.dart';

void main() {
  testWidgets('resilience center remains usable on narrow viewport', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const MaterialApp(
        home: ProjectResilienceCenterScreen(
          title: 'Project Repair',
          items: ['Missing Files', 'Orphan Files', 'Broken References'],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Project Repair'), findsOneWidget);
    expect(find.text('Missing Files'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
