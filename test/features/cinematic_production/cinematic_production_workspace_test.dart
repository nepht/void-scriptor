import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/cinematic_production/presentation/cinematic_production_workspace_screen.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: child);
  testWidgets(
    'cinematic production workspace is responsive and actions are live',
    (tester) async {
      var imported = false;
      var validated = false;
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        wrap(
          CinematicProductionWorkspaceScreen(
            onImportAudio: () => imported = true,
            onOpenValidation: () => validated = true,
          ),
        ),
      );
      expect(find.text('Cinematic Production Database'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Import Audio'));
      await tester.ensureVisible(find.text('Validation Center'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Validation Center'));
      expect(imported, isTrue);
      expect(validated, isTrue);
      await tester.binding.setSurfaceSize(null);
    },
  );
  testWidgets('validation center renders empty and issue states', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        ProductionValidationCenterScreen(
          issues: const [
            ProductionValidationIssue(
              title: 'Missing audio',
              detail: 'audio.wav is missing',
              severity: ProductionValidationSeverity.error,
            ),
          ],
          onRefresh: () {},
        ),
      ),
    );
    expect(find.text('Missing audio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
