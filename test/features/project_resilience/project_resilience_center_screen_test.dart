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

  testWidgets(
    'resilience center executes live action and reports busy safely',
    (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: ProjectResilienceCenterScreen(
            title: 'Project Cache',
            items: const ['Cache size: 2 KB'],
            actions: [
              ProjectResilienceAction(
                label: 'Clear Cache',
                icon: Icons.cleaning_services,
                onPressed: () async => calls++,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Clear Cache'));
      await tester.pump();
      expect(calls, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
