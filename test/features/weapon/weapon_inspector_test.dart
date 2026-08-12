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
    final container = tester
        .element(find.byType(InspectorResolver))
        .dependOnInheritedWidgetOfExactType<UncontrolledProviderScope>()!
        .container;
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'Void Dual Dagger',
            assetType: AssetType.weapon,
          ),
        );
    await tester.pump();

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
