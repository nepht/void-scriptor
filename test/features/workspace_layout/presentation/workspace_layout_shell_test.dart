import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/application/layout_controller.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/resizable_panel.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/workspace_layout_shell.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('renders explorer, workspace, and inspector panels', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        const WorkspaceLayoutShell(
          explorer: Text('EXPLORER'),
          workspace: Text('WORKSPACE'),
          inspector: Text('INSPECTOR'),
        ),
      ),
    );

    expect(find.text('EXPLORER'), findsOneWidget);
    expect(find.text('WORKSPACE'), findsOneWidget);
    expect(find.text('INSPECTOR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapses left panel when toggled via layout controller', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: WorkspaceLayoutShell(
              explorer: Text('EXPLORER'),
              workspace: Text('WORKSPACE'),
              inspector: Text('INSPECTOR'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('EXPLORER'), findsOneWidget);
    expect(find.byType(CollapsiblePanel), findsNothing);

    container.read(layoutProvider.notifier).toggleLeft();
    await tester.pump();

    // Collapsed: the left panel becomes a collapsible strip.
    expect(find.byType(CollapsiblePanel), findsOneWidget);
  });
}
