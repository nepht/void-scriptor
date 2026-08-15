import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/ai/presentation/prompt_compare_view.dart';

void main() {
  testWidgets('shows before/after with diff highlights and restore', (
    tester,
  ) async {
    String? restored;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromptCompareView(
            before: 'old prompt',
            after: 'old prompt\nnew line',
            onRestore: () => restored = 'restored',
          ),
        ),
      ),
    );

    expect(find.textContaining('old prompt'), findsWidgets);
    expect(find.byIcon(Icons.restore), findsOneWidget);

    await tester.tap(find.byIcon(Icons.restore));
    expect(restored, 'restored');
  });

  testWidgets('shows empty diff message when identical', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PromptCompareView(
            before: 'same',
            after: 'same',
            onRestore: () {},
          ),
        ),
      ),
    );
    expect(find.textContaining('No changes'), findsOneWidget);
  });
}
