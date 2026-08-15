import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_model.dart';
import 'package:void_scriptor/features/workspace_layout/domain/layout_preset.dart';
import 'package:void_scriptor/features/workspace_layout/presentation/layout_preset_menu.dart';

void main() {
  const presets = [
    LayoutPreset(
      name: 'Wide',
      layout: PanelLayout(
        leftWidth: 300,
        rightWidth: 300,
        leftCollapsed: false,
        rightCollapsed: false,
        splitRatio: 0.5,
      ),
    ),
    LayoutPreset(
      name: 'Focus',
      layout: PanelLayout(
        leftWidth: 200,
        rightWidth: 200,
        leftCollapsed: true,
        rightCollapsed: true,
        splitRatio: 0.75,
      ),
    ),
  ];

  testWidgets('renders a menu button and lists presets when opened', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayoutPresetMenu(
            presets: presets,
            activeName: null,
            onApply: (_) {},
            onSave: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    expect(find.text('Wide'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('invokes onApply when a preset is selected', (tester) async {
    String? applied;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayoutPresetMenu(
            presets: presets,
            activeName: null,
            onApply: (name) => applied = name,
            onSave: (_) {},
            onDelete: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wide'));
    await tester.pump();

    expect(applied, 'Wide');
  });

  testWidgets('invokes onSave with the typed name', (tester) async {
    String? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayoutPresetMenu(
            presets: presets,
            activeName: null,
            onApply: (_) {},
            onSave: (name) => saved = name,
            onDelete: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();

    // "Save current" entry prompts via a dialog with a text field.
    await tester.tap(find.text('Save current layout'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Custom');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(saved, 'Custom');
  });

  testWidgets('invokes onDelete when a preset is deleted', (tester) async {
    String? deleted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LayoutPresetMenu(
            presets: presets,
            activeName: null,
            onApply: (_) {},
            onSave: (_) {},
            onDelete: (name) => deleted = name,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IconButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-preset-Wide')));
    await tester.pump();

    expect(deleted, 'Wide');
  });
}
