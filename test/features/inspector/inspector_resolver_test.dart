import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:void_scriptor/core/selection/selection_controller.dart';
import 'package:void_scriptor/core/selection/selection_model.dart';
import 'package:void_scriptor/features/assets/domain/asset_type.dart';
import 'package:void_scriptor/features/inspector/presentation/inspector_resolver.dart';

void main() {
  testWidgets('inspector resolver shows empty state without selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: InspectorResolver())),
    );

    expect(find.text('No selection'), findsOneWidget);
    expect(
      find.text('Select an asset to inspect its properties.'),
      findsOneWidget,
    );
  });

  testWidgets('inspector resolver switches to typed asset inspector', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: InspectorResolver())),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(InspectorResolver)),
    );
    container
        .read(selectionProvider.notifier)
        .select(
          const SelectionModel(
            assetId: 'weapon-1',
            assetType: AssetType.weapon,
          ),
        );
    await tester.pump();

    expect(find.text('Weapon'), findsOneWidget);
    expect(find.text('weapon-1'), findsOneWidget);
  });
}
