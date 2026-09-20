import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/wardrobe/presentation/wardrobe_workspace_screen.dart';
import 'package:void_scriptor/features/workspace/presentation/workspace_resolver.dart';

void main() {
  testWidgets('wardrobe workspace renders detail sheet at desktop width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectionProvider.overrideWith(() => _WardrobeSelectionController()),
        ],
        child: const MaterialApp(home: WorkspaceResolver()),
      ),
    );

    final container = tester
        .element(find.byType(WorkspaceResolver))
        .dependOnInheritedWidgetOfExactType<UncontrolledProviderScope>()!
        .container;
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'Void Coat',
            assetType: AssetType.wardrobe,
          ),
        );
    await tester.pump();

    expect(find.byType(WardrobeWorkspaceScreen), findsOneWidget);
    for (final label in const [
      'Outfit Concept',
      'Orthographic Garment Views',
      'Wardrobe Components',
      'Main Wardrobe',
      'Material & Fabric',
      'Color Palette',
      'Accessories',
      'Dimensions & Construction Notes',
      'Close Up Detail',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('110 cm'), findsNothing);
    expect(find.text('#050507'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('wardrobe workspace remains single-column on narrow width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: WardrobeWorkspaceScreen(wardrobeId: 'Void Coat'),
        ),
      ),
    );
    expect(find.text('Specification'), findsOneWidget);
    expect(find.text('Color Palette'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WardrobeSelectionController extends SelectionController {
  @override
  SelectionModel? build() => null;
}
