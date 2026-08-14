import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/inspector/presentation/widgets/relation_section.dart';

void main() {
  testWidgets('relation deletion warns that the target asset is preserved', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await confirmRelationDeletion(
                  context,
                  targetName: 'Void Dual Dagger',
                );
              },
              child: const Text('Request delete'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Request delete'));
    await tester.pumpAndSettle();
    expect(find.text('Delete relation?'), findsOneWidget);
    expect(
      find.text(
        'This removes only the relation. Void Dual Dagger will not be deleted.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);

    await tester.tap(find.text('Request delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete relation'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });
}
