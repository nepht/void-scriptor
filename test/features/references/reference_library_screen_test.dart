import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:void_scriptor/features/references/domain/reference_models.dart';
import 'package:void_scriptor/features/references/presentation/reference_library_screen.dart';

void main() {
  const references = [
    ReferenceModel(
      id: 'face',
      projectId: 'p',
      ownerAssetId: 'qowner',
      type: ReferenceType.face,
      source: ReferenceSource.imported,
      name: 'Master Face',
      filePath: 'missing/master.png',
      priority: 100,
      primary: true,
      enabled: true,
    ),
    ReferenceModel(
      id: 'hair',
      projectId: 'p',
      ownerAssetId: 'qowner',
      type: ReferenceType.hair,
      source: ReferenceSource.generated,
      name: 'Combat Hair',
      filePath: 'missing/hair.png',
      priority: 90,
      primary: false,
      enabled: true,
    ),
  ];

  testWidgets(
    'reference library renders responsive cards and missing-file state',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ReferenceLibraryScreen(references: references)),
      );
      expect(find.text('Reference Library'), findsOneWidget);
      expect(find.text('★ PRIMARY'), findsOneWidget);
      expect(find.text('Reference file missing'), findsNWidgets(2));
      await tester.enterText(find.byType(TextField), 'combat');
      await tester.pump();
      expect(find.text('Combat Hair'), findsOneWidget);
      expect(find.text('Master Face'), findsNothing);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.binding.setSurfaceSize(null);
    },
  );
}
