import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

void main() {
  testWidgets('Outline without selection shows guided empty state', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: WorkspaceResolver(activeSection: 'Outline')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Story → Arc → Chapter → Scene'), findsOneWidget);
    expect(find.textContaining('Pilih novel'), findsOneWidget);
    expect(
      find.text('Select an asset from Explorer to open its workspace.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-Outline empty state does not show outline guidance', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(body: WorkspaceResolver(activeSection: 'Manuscript')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Story → Arc → Chapter → Scene'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
