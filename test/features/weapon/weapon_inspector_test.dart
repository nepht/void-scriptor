import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/inspector/presentation/inspector_resolver.dart';
import 'package:void_scriptor/features/inspector/presentation/inspectors/weapon_inspector.dart';

void main() {
  testWidgets('weapon selection resolves to WeaponInspector', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          selectionProvider.overrideWith(() => _WeaponSelectionController()),
        ],
        child: const MaterialApp(home: InspectorResolver()),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InspectorResolver)),
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
    // INS-BUG-03 (vs-hunt-20260913-inspector): the inspector now renders a
    // real loading branch first; pump once more so the provider settles
    // (null session -> 'Unknown asset' data branch) before asserting the
    // resolved structure. Intent unchanged: selection mounts the full
    // WeaponInspector with its Properties and Relations sections.
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(WeaponInspector), findsOneWidget);
    expect(find.text('Properties'), findsOneWidget);
    expect(find.text('Relations'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _WeaponSelectionController extends SelectionController {
  @override
  SelectionModel? build() => null;
}
