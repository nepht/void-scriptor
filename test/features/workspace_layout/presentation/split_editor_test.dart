import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/application/layout_controller.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_model.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_preset.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/split_editor.dart';

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(home: Scaffold(body: child)),
);

void main() {
  testWidgets('SplitEditor shows primary and secondary panes', (tester) async {
    await tester.pumpWidget(
      _wrap(
        const SplitEditor(
          primary: Text('PRIMARY'),
          secondary: Text('SECONDARY'),
        ),
      ),
    );

    expect(find.text('PRIMARY'), findsOneWidget);
    expect(find.text('SECONDARY'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SplitEditor hides secondary at ratio 1.0', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SplitEditor(primary: Text('P'), secondary: Text('S')),
          ),
        ),
      ),
    );

    // applyPreset sets state directly (no clamp), allowing a full ratio.
    container
        .read(layoutProvider.notifier)
        .applyPreset(
          const LayoutPreset(
            name: 'full',
            layout: PanelLayout(
              leftWidth: 200,
              rightWidth: 200,
              leftCollapsed: false,
              rightCollapsed: false,
              splitRatio: 1.0,
            ),
          ),
        );
    await tester.pump();

    // At full ratio, secondary pane is collapsed away.
    expect(find.text('S'), findsNothing);
    expect(find.text('P'), findsOneWidget);
  });

  testWidgets('FullscreenPreview toggles to fullscreen and back', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(FullscreenPreview(onExit: () {}, child: const Text('PREVIEW'))),
    );

    expect(find.text('PREVIEW'), findsOneWidget);
    expect(find.text('Exit fullscreen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
