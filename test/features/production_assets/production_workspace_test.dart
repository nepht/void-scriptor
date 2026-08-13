import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/features/production_assets/presentation/production_asset_workspace_screen.dart';
import 'package:void_scriptor/features/scene_assets/presentation/scene_asset_panel.dart';
import 'package:void_scriptor/shared/widgets/scale_comparison_widget.dart';

void main() {
  testWidgets(
    'creature workspace renders production sections without overflow',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 800,
              child: ProductionAssetWorkspaceScreen(
                kind: ProductionAssetKind.creature,
              ),
            ),
          ),
        ),
      );
      expect(find.text('CREATURES'), findsOneWidget);
      expect(find.text('Physical'), findsOneWidget);
      expect(find.text('Abilities'), findsOneWidget);
      expect(find.text('Modes'), findsOneWidget);
      expect(find.byType(ScaleComparisonWidget), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('vehicle and prop workspaces fit narrow viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final kind in [
      ProductionAssetKind.vehicle,
      ProductionAssetKind.prop,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: ProductionAssetWorkspaceScreen(kind: kind)),
        ),
      );
      expect(
        find.text(kind == ProductionAssetKind.vehicle ? 'VEHICLES' : 'PROPS'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('scene asset panel groups assets and exposes add action', (
    tester,
  ) async {
    var added = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SceneAssetPanel(
            groups: const {
              'Characters': ['Qowner'],
              'Creatures': ['Byte'],
              'Vehicles': [],
              'Props': ['Coffee Cup', 'Chair'],
              'Environment': ['Beach'],
            },
            onAddAsset: () => added = true,
          ),
        ),
      ),
    );
    expect(find.text('SCENE ASSETS'), findsOneWidget);
    expect(find.text('Byte'), findsOneWidget);
    expect(find.text('Coffee Cup'), findsOneWidget);
    await tester.tap(find.text('Add Asset'));
    expect(added, isTrue);
  });
}
