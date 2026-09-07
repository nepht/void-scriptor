import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/inspector/presentation/inspector_resolver.dart';
import 'package:void_scriptor/features/projects/presentation/project_persistence_providers.dart';

void main() {
  testWidgets(
    'selection from another project does not surface stale inspector',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [currentProjectIdProvider.overrideWithValue('project-b')],
          child: const MaterialApp(home: InspectorResolver()),
        ),
      );
      final container = ProviderScope.containerOf(
        tester.element(find.byType(InspectorResolver)),
      );
      container
          .read(selectionProvider.notifier)
          .select(
            const SelectionModel(
              assetId: 'weapon-from-saga',
              assetType: AssetType.weapon,
              projectId: 'project-a',
            ),
          );
      await tester.pump();

      expect(find.text('No selection'), findsOneWidget);
      expect(find.text('weapon-from-saga'), findsNothing);
    },
  );

  testWidgets('selection from the active project resolves normally', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [currentProjectIdProvider.overrideWithValue('project-b')],
        child: const MaterialApp(home: InspectorResolver()),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InspectorResolver)),
    );
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'weapon-tesnovel',
            assetType: AssetType.weapon,
            projectId: 'project-b',
          ),
        );
    await tester.pump();

    expect(find.text('Weapon'), findsOneWidget);
    expect(find.text('weapon-tesnovel'), findsOneWidget);
  });
}
