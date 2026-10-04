import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/weapon/presentation/weapon_workspace_screen.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

void main() {
  testWidgets('weapon workspace renders technical detail sheet on desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectionProvider.overrideWith(() => _WeaponSelectionController()),
        ],
        child: const MaterialApp(home: WorkspaceResolver()),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(WorkspaceResolver)),
      listen: false,
    );
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'Void Dual Dagger',
            assetType: AssetType.weapon,
          ),
        );
    await tester.pump();

    expect(find.byType(WeaponWorkspaceScreen), findsOneWidget);
    for (final label in const [
      'Concept',
      'Orthographic Views',
      'Exploded View',
      'Detail Panels',
      'Material & Texture',
      'Color Palette',
      'Dimensions & Construction',
      'Function / Combat Mode',
      'Technical Notes',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('2600 mm'), findsNothing);
    expect(find.text('#6A00FF'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weapon workspace resolves requested asset sections', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WeaponWorkspaceScreen(
            weaponId: 'Void Dual Dagger',
            activeSection: 'Variants',
          ),
        ),
      ),
    );
    expect(find.text('Variants'), findsOneWidget);
    expect(find.text('Concept'), findsNothing);
    expect(find.text('Technical Notes'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('weapon workspace remains vertical on narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WeaponWorkspaceScreen(weaponId: 'Void Dual Dagger'),
        ),
      ),
    );
    expect(find.text('Specification'), findsOneWidget);
    expect(find.text('Dimensions'), findsOneWidget);
    expect(find.text('References'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WeaponSelectionController extends SelectionController {
  @override
  SelectionModel? build() => null;
}
