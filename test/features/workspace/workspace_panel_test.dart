import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_panel.dart';

void main() {
  testWidgets('workspace tabs are explicitly deferred on narrow layouts', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: Scaffold(body: WorkspacePanel())),
      ),
    );
    await tester.pump();

    expect(find.text('Overview'), findsOneWidget);
    expect(find.byTooltip('Character Sheet (deferred)'), findsOneWidget);
    expect(find.byTooltip('Identity (deferred)'), findsOneWidget);
    expect(find.byTooltip('References (deferred)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
